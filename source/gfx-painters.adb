--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with GFX.Implementation.Snapshots;
with GFX.Points;

package body GFX.Painters is

   ---------------
   -- Draw_Line --
   ---------------

   procedure Draw_Line
     (Self           : in out Painter'Class;
      X1, Y1, X2, Y2 : GFX.Real)
   is
      use type Interfaces.Unsigned_32;

      S : GFX.Points.GF_Point := (X1, Y1);
      E : GFX.Points.GF_Point := (X2, Y2);

   begin
      if not Self.Clip_Region_Stored then
         declare
            C : constant GFX.Clip_Regions.GX_Clip_Region :=
              Self.Clip_Region_Value;
            A : GFX.Points.GF_Point := (C.Left, C.Top);
            B : GFX.Points.GF_Point := (C.Right, C.Bottom);

         begin
            A := GFX.Implementation.Snapshots.CSS_To_Device.Map (A);
            B := GFX.Implementation.Snapshots.CSS_To_Device.Map (B);
            --  ??? Should it be better synchronized with device pixels, like
            --  move clipping edges a bit out to clip between device pixels ???

            GFX.Implementation.Snapshots.Buffer
              (GFX.Implementation.Snapshots.Length) :=
              (Kind        => GFX.Implementation.Snapshots.Clip,
               Clip_Region =>
                 (Top => A.Y, Left => A.X, Right => B.X, Bottom => B.Y));
            GFX.Implementation.Snapshots.Length := @ + 1;
            Self.Clip_Region_Stored := True;
         end;
      end if;

      if not Self.Settings_Stored then
         GFX.Implementation.Snapshots.Buffer
           (GFX.Implementation.Snapshots.Length) :=
           (Kind  => GFX.Implementation.Snapshots.Settings,
            Color => Self.Color_Value,
            Width =>
              (if Self.Width_Value = 1.0
               then 1.0 else Self.Width_Value * 1.72930288));
         --  XXX Width should be scaled properly !!!
         GFX.Implementation.Snapshots.Length := @ + 1;
         Self.Settings_Stored := True;
      end if;

      S := Self.Transformation.Map (S);
      E := Self.Transformation.Map (E);

      S := GFX.Implementation.Snapshots.CSS_To_Device.Map (S);
      E := GFX.Implementation.Snapshots.CSS_To_Device.Map (E);

      GFX.Implementation.Snapshots.Buffer
        (GFX.Implementation.Snapshots.Length) :=
        (Kind        => GFX.Implementation.Snapshots.Line,
         Start_Point => S,
         End_Point   => E);
      GFX.Implementation.Snapshots.Length := @ + 1;
   end Draw_Line;

   ---------------------
   -- Set_Clip_Region --
   ---------------------

   procedure Set_Clip_Region
     (Self : in out Painter'Class;
      To   : GFX.Clip_Regions.GX_Clip_Region)
   is
      use type GFX.Clip_Regions.GX_Clip_Region;

   begin
      if Self.Clip_Region_Value /= To then
         Self.Clip_Region_Value  := To;
         Self.Clip_Region_Stored := False;
      end if;
   end Set_Clip_Region;

   ---------------
   -- Set_Color --
   ---------------

   procedure Set_Color (Self : in out Painter'Class; To : GFX.RGBA8888) is
   begin
      if Self.Color_Value /= To then
         Self.Color_Value     := To;
         Self.Settings_Stored := False;
      end if;
   end Set_Color;

   ------------------------
   -- Set_Transformation --
   ------------------------

   procedure Set_Transformation
     (Self : in out Painter'Class;
      To   : GFX.Transformers.GX_Transformer) is
   begin
      Self.Transformation := To;
   end Set_Transformation;

   ---------------
   -- Set_Width --
   ---------------

   procedure Set_Width (Self : in out Painter'Class; To : GFX.Real) is
   begin
      if Self.Width_Value /= To then
         Self.Width_Value     := To;
         Self.Settings_Stored := False;
      end if;
   end Set_Width;

end GFX.Painters;
