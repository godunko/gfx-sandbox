--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

pragma Ada_2022;

package body GFX.CSS is

   ----------------
   -- Border_Box --
   ----------------

   procedure Border_Box
     (Self           : CSS_Box;
      Clip_Region    : out GFX.Clip_Regions.GX_Clip_Region;
      Transformation : out GFX.Transformers.Transformer) is
   begin
      Padding_Box (Self, Clip_Region, Transformation);

      Clip_Region.Top    := @ - Self.Computed_Border_Top;
      Clip_Region.Left   := @ - Self.Computed_Border_Left;
      Clip_Region.Right  := @ + Self.Computed_Border_Right;
      Clip_Region.Bottom := @ + Self.Computed_Border_Bottom;

      GFX.Transformers.Translate
        (Transformation,
         -Self.Computed_Border_Left,
         -Self.Computed_Border_Top);
   end Border_Box;

   -----------------
   -- Content_Box --
   -----------------

   procedure Content_Box
     (Self           : CSS_Box;
      Clip_Region    : out GFX.Clip_Regions.GX_Clip_Region;
      Transformation : out GFX.Transformers.Transformer) is
   begin
      Clip_Region.Top    := Self.Computed_Content_Y;
      Clip_Region.Left   := Self.Computed_Content_X;
      Clip_Region.Right  :=
        Self.Computed_Content_X + Self.Computed_Content_Width;
      Clip_Region.Bottom :=
        Self.Computed_Content_Y + Self.Computed_Content_Height;

      Transformation.Set_Identity;
      Transformation.Translate
        (Self.Computed_Content_X,
         Self.Computed_Content_Y);
   end Content_Box;

   ----------------
   -- Margin_Box --
   ----------------

   procedure Margin_Box
     (Self           : CSS_Box;
      Clip_Region    : out GFX.Clip_Regions.GX_Clip_Region;
      Transformation : out GFX.Transformers.Transformer) is
   begin
      Border_Box (Self, Clip_Region, Transformation);

      Clip_Region.Top    := @ - Self.Computed_Margin_Top;
      Clip_Region.Left   := @ - Self.Computed_Margin_Left;
      Clip_Region.Right  := @ + Self.Computed_Margin_Right;
      Clip_Region.Bottom := @ + Self.Computed_Margin_Bottom;

      GFX.Transformers.Translate
        (Transformation,
         -Self.Computed_Margin_Left,
         -Self.Computed_Margin_Top);
   end Margin_Box;

   -----------------
   -- Padding_Box --
   -----------------

   procedure Padding_Box
     (Self           : CSS_Box;
      Clip_Region    : out GFX.Clip_Regions.GX_Clip_Region;
      Transformation : out GFX.Transformers.Transformer) is
   begin
      Content_Box (Self, Clip_Region, Transformation);

      Clip_Region.Top    := @ - Self.Computed_Padding_Top;
      Clip_Region.Left   := @ - Self.Computed_Padding_Left;
      Clip_Region.Right  := @ + Self.Computed_Padding_Right;
      Clip_Region.Bottom := @ + Self.Computed_Padding_Bottom;

      GFX.Transformers.Translate
        (Transformation,
         -Self.Computed_Padding_Left,
         -Self.Computed_Padding_Top);
   end Padding_Box;

end GFX.CSS;
