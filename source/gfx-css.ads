--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

package GFX.CSS
  with Pure
is

   --  type Distance_Unit is
   --    (Centimeters,
   --     Millimeters,
   --     Quarter_Millimeters,
   --     Inches,
   --     Picas,
   --     Points,
   --     Pixels);

   type CSS_Length_Units is
     (em_Unit,    --  font size of the element
      ex_Unit,    --  x-height of the element’s font
      ch_Unit,
      --  character advance of the “0” (ZERO, U+0030) glyph in the
      --  element’s font
      rem_Unit,   --  font size of the root element
      vw_Unit,    --  1% of viewport’s width
      vh_Unit,    --  1% of viewport’s height
      vmin_Unit,  --  1% of viewport’s smaller dimension
      vmax_Unit,  --  1% of viewport’s larger dimension

      cm_Unit,    --  centimeters
      mm_Unit,    --  millimeters
      Q_Unit,     --  quarter-millimeters
      in_Unit,    --  inches
      pc_Unit,    --  picas
      pt_Unit,    --  points
      px_Unit);   --  pixels

   subtype CSS_Pixel_Length is GFX.Real;

   --  content-box
   --  padding-box
   --  border-box
   --  margin-box
   --  fill-box
   --  stroke-box
   --  view-box
   --  visual-box = content-box | padding-box | border-box
   --  layout-box = visual-box | margin-box
   --  paint-box  = layout-box | fill-box | stroke-box
   --  coord-box  = paint-box | view-box

   type CSS_Box is record
      Computed_Margin_Top     : CSS_Pixel_Length;
      Computed_Margin_Right   : CSS_Pixel_Length;
      Computed_Margin_Bottom  : CSS_Pixel_Length;
      Computed_Margin_Left    : CSS_Pixel_Length;

      Computed_Padding_Top    : CSS_Pixel_Length;
      Computed_Padding_Right  : CSS_Pixel_Length;
      Computed_Padding_Bottom : CSS_Pixel_Length;
      Computed_Padding_Left   : CSS_Pixel_Length;

      Computed_Border_Top     : CSS_Pixel_Length;
      Computed_Border_Right   : CSS_Pixel_Length;
      Computed_Border_Bottom  : CSS_Pixel_Length;
      Computed_Border_Left    : CSS_Pixel_Length;

      Computed_Content_X      : CSS_Pixel_Length;
      Computed_Content_Y      : CSS_Pixel_Length;
      Computed_Content_Width  : CSS_Pixel_Length;
      Computed_Content_Height : CSS_Pixel_Length;
   end record;

end GFX.CSS;
