--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Types;

with GFX.Implementation;

generic
   with function Get_Pixel
     (X : GFX.Implementation.Device_Pixel_Index;
      Y : GFX.Implementation.Device_Pixel_Index) return GFX.RGBA8888;

   with procedure Set_Pixel
     (X     : GFX.Implementation.Device_Pixel_Index;
      Y     : GFX.Implementation.Device_Pixel_Index;
      Color : GFX.RGBA8888);

   Device_Width  : GFX.Implementation.Device_Pixel_Index;
   Device_Height : GFX.Implementation.Device_Pixel_Index;

package GFX.Rasterizer
  --  with Preelaborate
is

   procedure Draw_Line
     (X1    : GFX.Implementation.Device_Pixel_Coordinate;
      Y1    : GFX.Implementation.Device_Pixel_Coordinate;
      X2    : GFX.Implementation.Device_Pixel_Coordinate;
      Y2    : GFX.Implementation.Device_Pixel_Coordinate;
      Color : GFX.RGBA8888);

private

   type Fixed_26_6 is new A0B.Types.Integer_32;

   function To_Fixed_26_6 (Item : GFX.Real) return Fixed_26_6;

   --  type Fixed_16_16 is new A0B.Types.Integer_32;

end GFX.Rasterizer;
