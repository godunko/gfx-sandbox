--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with GFX.Clip_Regions;
with GFX.Implementation.Snapshots;
with GFX.Painters;
with GFX.Transformers;

package body GFX.Widgets is

   procedure Content_Box_Clip_Region
     (Self        : Abstract_Widget'Class;
      Clip_Region : out GFX.Clip_Regions.GX_Clip_Region);

   procedure Content_Box_Transformation
     (Self           : Abstract_Widget'Class;
      Transformation : out GFX.Transformers.Transformer);

   -----------------------------
   -- Content_Box_Clip_Region --
   -----------------------------

   procedure Content_Box_Clip_Region
     (Self        : Abstract_Widget'Class;
      Clip_Region : out GFX.Clip_Regions.GX_Clip_Region) is
   begin
      Clip_Region.Top := Self.Box.Computed_Content_Y;
      Clip_Region.Left := Self.Box.Computed_Content_X;
      Clip_Region.Right :=
        Self.Box.Computed_Content_X + Self.Box.Computed_Content_Width;
      Clip_Region.Bottom :=
        Self.Box.Computed_Content_Y + Self.Box.Computed_Content_Height;
   end Content_Box_Clip_Region;

   --------------------------------
   -- Content_Box_Transformation --
   --------------------------------

   procedure Content_Box_Transformation
     (Self           : Abstract_Widget'Class;
      Transformation : out GFX.Transformers.Transformer) is
   begin
      Transformation.Set_Identity;

      Transformation.Translate
        (Self.Box.Computed_Content_X,
         Self.Box.Computed_Content_Y);
   end Content_Box_Transformation;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Self   : out Abstract_Widget'Class;
      Width  : A0B.Types.Integer_32;
      Height : A0B.Types.Integer_32) is
   begin
      GFX.Implementation.Snapshots.Root := Self'Unchecked_Access;

      Self.Box.Computed_Border_Bottom := 2.0;
      Self.Box.Computed_Border_Left   := 2.0;
      Self.Box.Computed_Border_Right  := 2.0;
      Self.Box.Computed_Border_Top    := 2.0;

      Self.Box.Computed_Padding_Bottom := 2.0;
      Self.Box.Computed_Padding_Left   := 2.0;
      Self.Box.Computed_Padding_Right  := 2.0;
      Self.Box.Computed_Padding_Top    := 2.0;

      Self.Box.Computed_Margin_Bottom := 2.0;
      Self.Box.Computed_Margin_Left   := 2.0;
      Self.Box.Computed_Margin_Right  := 2.0;
      Self.Box.Computed_Margin_Top    := 2.0;

      Self.Box.Computed_Content_X :=
        Self.Box.Computed_Margin_Left
          + Self.Box.Computed_Border_Left
          + Self.Box.Computed_Padding_Left
          - 0.5;
      Self.Box.Computed_Content_Y :=
        Self.Box.Computed_Margin_Top
          + Self.Box.Computed_Border_Top
          + Self.Box.Computed_Padding_Top
          - 0.5;
      Self.Box.Computed_Content_Width :=
        GFX.Real (Width)
          - Self.Box.Computed_Content_X
          - Self.Box.Computed_Margin_Right
          - Self.Box.Computed_Border_Right
          - Self.Box.Computed_Padding_Right
          + 0.5;
      Self.Box.Computed_Content_Height :=
        GFX.Real (Height)
          - Self.Box.Computed_Content_Y
          - Self.Box.Computed_Margin_Bottom
          - Self.Box.Computed_Border_Bottom
          - Self.Box.Computed_Padding_Bottom
          + 0.5;
   end Initialize;

   -----------
   -- Paint --
   -----------

   not overriding procedure Paint (Self : in out Abstract_Widget) is
      Color   : constant GFX.RGBA8888 := GFX.To_RGBA (0, 255, 0, 255);

      Painter        : GFX.Painters.Painter;
      Transformation : GFX.Transformers.Transformer;
      Clip_Region    : GFX.Clip_Regions.GX_Clip_Region;
      X              : GFX.Real;
      Y              : GFX.Real;

   begin
      Self.Content_Box_Transformation (Transformation);
      Self.Content_Box_Clip_Region (Clip_Region);

      Painter.Set_Transformation (Transformation);
      Painter.Set_Clip_Region (Clip_Region);

      Painter.Set_Color (GFX.To_RGBA (127, 127, 127, 255));
      Painter.Set_Width (3.0);
      Painter.Draw_Line (1.0, 5.0, 400.0, 5.0);

      Painter.Set_Color (Color);
      Painter.Set_Width (1.0);

      Y := 50.5;
      X := 0.0;

      for J in 1 .. 50 loop
         Painter.Draw_Line (X, Y, X + 4.5, Y);
         Painter.Draw_Line (X + 4.5, Y, X + 5.5, Y + 20.0);
         Painter.Draw_Line (X + 5.5, Y + 20.0, X + 9.0, Y + 20.0);
         Painter.Draw_Line (X + 9.0, Y + 20.0, X + 10.0, Y);

         X := @ + 10.0;
      end loop;

      Y := 75.5;
      X := 0.0;

      for J in 1 .. 25 loop
         Painter.Draw_Line (X, Y, X + 9.5, Y);
         Painter.Draw_Line (X + 9.5, Y, X + 10.5, Y + 20.0);
         Painter.Draw_Line (X + 10.5, Y + 20.0, X + 19.0, Y + 20.0);
         Painter.Draw_Line (X + 19.0, Y + 20.0, X + 20.0, Y);

         X := @ + 20.0;
      end loop;

      Y := 100.5;
      X := 0.0;

      for J in 1 .. 17 loop
         Painter.Draw_Line (X, Y, X + 14.5, Y);
         Painter.Draw_Line (X + 14.5, Y, X + 15.5, Y + 20.0);
         Painter.Draw_Line (X + 15.5, Y + 20.0, X + 29.0, Y + 20.0);
         Painter.Draw_Line (X + 29.0, Y + 20.0, X + 30.0, Y);

         X := @ + 30.0;
      end loop;

      Y := 125.5;
      X := 0.0;

      for J in 1 .. 12 loop
         Painter.Draw_Line (X, Y, X + 19.5, Y);
         Painter.Draw_Line (X + 19.5, Y, X + 20.5, Y + 20.0);
         Painter.Draw_Line (X + 20.5, Y + 20.0, X + 39.0, Y + 20.0);
         Painter.Draw_Line (X + 39.0, Y + 20.0, X + 40.0, Y);

         X := @ + 40.0;
      end loop;
   end Paint;

end GFX.Widgets;
