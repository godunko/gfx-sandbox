--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with GFX.Implementation;
with GFX.Points;

package body GFX.Painters is

   ---------------
   -- Draw_Line --
   ---------------

   procedure Draw_Line
     (Self           : in out Painter'Class;
      X1, Y1, X2, Y2 : GFX.Real)
   is
      use type A0B.Types.Unsigned_32;

      S : GFX.Points.Point := (X1, Y1);
      E : GFX.Points.Point := (X2, Y2);

   begin
      if not Self.Color_Stored then
         GFX.Implementation.Buffer (GFX.Implementation.Length) :=
           (Kind  => GFX.Implementation.Color,
            Color => Self.Color_Value);
         GFX.Implementation.Length := @ + 1;
         Self.Color_Stored := True;
      end if;

      S := Self.Transformation.Map (S);
      E := Self.Transformation.Map (E);

      GFX.Implementation.Buffer (GFX.Implementation.Length) :=
        (Kind        => GFX.Implementation.Line,
         Start_Point => S,
         End_Point   => E);
      GFX.Implementation.Length := @ + 1;
   end Draw_Line;

   ---------------
   -- Set_Color --
   ---------------

   procedure Set_Color (Self : in out Painter'Class; Color : GFX.RGBA8888) is
   begin
      if Self.Color_Value /= Color then
         Self.Color_Value  := Color;
         Self.Color_Stored := False;
      end if;
   end Set_Color;

   ------------------------
   -- Set_Transformation --
   ------------------------

   procedure Set_Transformation
     (Self : in out Painter'Class;
      To   : GFX.Transformers.Transformer) is
   begin
      Self.Transformation := To;
   end Set_Transformation;

end GFX.Painters;
