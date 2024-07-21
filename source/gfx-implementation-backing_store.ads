--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with GFX.Rasteriser;

package GFX.Implementation.Backing_Store
  with Preelaborate
is

   type Storage_Array is array
     (Interfaces.Unsigned_32 range 0 .. 4_095)
        of GFX.RGBA8888;

   procedure Clear;

   function Get_Pixel
     (X : GFX.Rasteriser.Device_Pixel_Index;
      Y : GFX.Rasteriser.Device_Pixel_Index) return GFX.RGBA8888;

   procedure Set_Pixel
     (X     : GFX.Rasteriser.Device_Pixel_Index;
      Y     : GFX.Rasteriser.Device_Pixel_Index;
      Color : GFX.RGBA8888);

   function Storage return not null access Storage_Array;

   procedure Set_Size
     (X      : GFX.Rasteriser.Device_Pixel_Index;
      Y      : GFX.Rasteriser.Device_Pixel_Index;
      Width  : GFX.Rasteriser.Device_Pixel_Count;
      Height : GFX.Rasteriser.Device_Pixel_Count);

end GFX.Implementation.Backing_Store;
