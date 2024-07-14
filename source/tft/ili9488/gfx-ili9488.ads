--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  3.5" ILI9488 320x480 SPI display

with GFX.Drawing;
with GFX.Implementation.Backing_Store;
with GFX.Transformers;

package GFX.ILI9488 is

   procedure Set_Pixel
     (X     : GFX.Drawing.Device_Pixel_Index;
      Y     : GFX.Drawing.Device_Pixel_Index;
      Color : GFX.RGBA8888);

   function Get_Pixel
     (X : GFX.Drawing.Device_Pixel_Index;
      Y : GFX.Drawing.Device_Pixel_Index) return GFX.RGBA8888;

   procedure Initialize;

   procedure Enable;

   procedure Set
     (X : GFX.Drawing.Device_Pixel_Index;
      Y : GFX.Drawing.Device_Pixel_Index;
      W : GFX.Drawing.Device_Pixel_Count;
      H : GFX.Drawing.Device_Pixel_Count;
      S : not null access GFX.Implementation.Backing_Store.Storage_Array);

   procedure CSS_Device_Transformation
     (Transformation : out GFX.Transformers.GX_Transformer);

end GFX.ILI9488;
