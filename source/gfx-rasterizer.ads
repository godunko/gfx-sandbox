--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with A0B.Types;

with GFX.Drawing;

generic
   with function Get_Pixel
     (X : GFX.Drawing.Device_Pixel_Index;
      Y : GFX.Drawing.Device_Pixel_Index) return GFX.RGBA8888;

   with procedure Set_Pixel
     (X     : GFX.Drawing.Device_Pixel_Index;
      Y     : GFX.Drawing.Device_Pixel_Index;
      Color : GFX.RGBA8888);

   Device_Width  : GFX.Drawing.Device_Pixel_Index;
   Device_Height : GFX.Drawing.Device_Pixel_Index;

package GFX.Rasterizer
  with Preelaborate
is

   procedure Set_Settings
     (Color : GFX.RGBA8888;
      Width : GFX.Real);

   procedure Draw_Line
     (X1    : GFX.Drawing.Device_Pixel_Coordinate;
      Y1    : GFX.Drawing.Device_Pixel_Coordinate;
      X2    : GFX.Drawing.Device_Pixel_Coordinate;
      Y2    : GFX.Drawing.Device_Pixel_Coordinate);
   --  Draw straight line between two given points.

   procedure Set_Clip
     (Top    : GFX.Drawing.Device_Pixel_Coordinate;
      Left   : GFX.Drawing.Device_Pixel_Coordinate;
      Right  : GFX.Drawing.Device_Pixel_Coordinate;
      Bottom : GFX.Drawing.Device_Pixel_Coordinate);

private

   type Fixed_26_6 is new A0B.Types.Integer_32;

   function To_Fixed_26_6 (Item : GFX.Real) return Fixed_26_6;

   --  type Fixed_16_16 is new A0B.Types.Integer_32;

end GFX.Rasterizer;
