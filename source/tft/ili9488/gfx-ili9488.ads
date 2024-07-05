--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  ILI9488 320x480 SPI display

with GFX.Implementation.Backing_Store;

package GFX.ILI9488 is

   procedure Set_Pixel
     (X     : GFX.Implementation.Device_Point_Coordinate;
      Y     : GFX.Implementation.Device_Point_Coordinate;
      Color : GFX.RGBA8888);

   function Get_Pixel
     (X : GFX.Implementation.Device_Point_Coordinate;
      Y : GFX.Implementation.Device_Point_Coordinate) return GFX.RGBA8888;

   procedure Initialize;

   procedure Enable;

   procedure Set
     (X : GFX.Implementation.Device_Point_Coordinate;
      Y : GFX.Implementation.Device_Point_Coordinate;
      S : not null access GFX.Implementation.Backing_Store.Storage_Array);

end GFX.ILI9488;
