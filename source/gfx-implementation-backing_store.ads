--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package GFX.Implementation.Backing_Store
  with Preelaborate
is

   type Storage_Array is array
     (GFX.Implementation.Device_Pixel_Index range 0 .. 1_023)
        of GFX.RGBA8888;

   procedure Clear;

   function Get_Pixel
     (X : GFX.Implementation.Device_Pixel_Index;
      Y : GFX.Implementation.Device_Pixel_Index) return GFX.RGBA8888;

   procedure Set_Pixel
     (X     : GFX.Implementation.Device_Pixel_Index;
      Y     : GFX.Implementation.Device_Pixel_Index;
      Color : GFX.RGBA8888);

   function Storage return not null access Storage_Array;

   procedure Set_Size
     (Width  : GFX.Implementation.Device_Pixel_Count;
      Height : GFX.Implementation.Device_Pixel_Count);

end GFX.Implementation.Backing_Store;
