--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body GFX.Implementation.Backing_Store is

   Pixels : aliased Storage_Array
     with Linker_Section => ".dtcm.bss";
   Width  : GFX.Rasteriser.Device_Pixel_Count;
   Height : GFX.Rasteriser.Device_Pixel_Count;

   -----------
   -- Clear --
   -----------

   procedure Clear is
   begin
      for J in 0 .. (Width * Height) - 1 loop
         Pixels (J) := To_RGBA (0, 0, 0, 0);
      end loop;
   end Clear;

   ---------------
   -- Get_Pixel --
   ---------------

   function Get_Pixel
     (X : GFX.Rasteriser.Device_Pixel_Index;
      Y : GFX.Rasteriser.Device_Pixel_Index) return GFX.RGBA8888 is
   begin
      return Pixels (Y * Width + X);
   end Get_Pixel;

   ---------------
   -- Set_Pixel --
   ---------------

   procedure Set_Pixel
     (X     : GFX.Rasteriser.Device_Pixel_Index;
      Y     : GFX.Rasteriser.Device_Pixel_Index;
      Color : GFX.RGBA8888) is
   begin
      if X < Width and Y < Height then
         Pixels (Y * Width + X) := Color;
      end if;
   end Set_Pixel;

   --------------
   -- Set_Size --
   --------------

   procedure Set_Size
     (Width  : GFX.Rasteriser.Device_Pixel_Count;
      Height : GFX.Rasteriser.Device_Pixel_Count) is
   begin
      Backing_Store.Width  := Width;
      Backing_Store.Height := Height;
   end Set_Size;

   -------------
   -- Storage --
   -------------

   function Storage return not null access Storage_Array is
   begin
      return Pixels'Unchecked_Access;
   end Storage;

end GFX.Implementation.Backing_Store;
