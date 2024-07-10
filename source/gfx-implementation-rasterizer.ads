--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This package provides subprograms to help to rasterize basic geometric
--  primitives on grayscale pixel buffers.
--
--  These subprograms need to be combined with color scaling and color blending
--  subprograms to draw real image.
--
--  Access to span draw subprogram versus generic with formal span draw
--  subprogram is selected to have minimal code footprint.

pragma Restrictions (No_Elaboration_Code);

package GFX.Implementation.Rasterizer
  with Preelaborate
is

   type Fill_Span_Subprogram is
     access procedure (X        : GFX.Implementation.Device_Pixel_Index;
                       Y        : GFX.Implementation.Device_Pixel_Index;
                       Width    : GFX.Implementation.Device_Pixel_Count;
                       Coverage : GFX.Implementation.Grayscale);

   procedure Draw_Line
     (Point_A   : GFX.Points.GF_Point;
      Point_B   : GFX.Points.GF_Point;
      Width     : GFX.Real;
      Fill_Span : not null access procedure
        (X        : GFX.Implementation.Device_Pixel_Index;
         Y        : GFX.Implementation.Device_Pixel_Index;
         Width    : GFX.Implementation.Device_Pixel_Count;
         Coverage : GFX.Implementation.Grayscale));
      --  Draw_Span : not null Draw_Span_Subprogram);
   --  Draw straight line between given two points of the given width. It
   --  supports anti-aliasing.

private

   procedure Internal_Fill_Rectangle
     (Top       : GFX.Implementation.Device_Pixel_Coordinate;
      Left      : GFX.Implementation.Device_Pixel_Coordinate;
      Right     : GFX.Implementation.Device_Pixel_Coordinate;
      Bottom    : GFX.Implementation.Device_Pixel_Coordinate;
      Fill_Span : not null access procedure
        (X        : GFX.Implementation.Device_Pixel_Index;
         Y        : GFX.Implementation.Device_Pixel_Index;
         Width    : GFX.Implementation.Device_Pixel_Count;
         Coverage : GFX.Implementation.Grayscale));
      --  Draw_Span : not null Draw_Span_Subprogram);
   --  Draw rectangle.

end GFX.Implementation.Rasterizer;
