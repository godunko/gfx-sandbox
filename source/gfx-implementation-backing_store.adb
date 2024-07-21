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
   X_Min  : GFX.Rasteriser.Device_Pixel_Index;
   X_Max  : GFX.Rasteriser.Device_Pixel_Index;
   Y_Min  : GFX.Rasteriser.Device_Pixel_Index;
   Y_Max  : GFX.Rasteriser.Device_Pixel_Index;

   function Offset
     (X : GFX.Rasteriser.Device_Pixel_Index;
      Y : GFX.Rasteriser.Device_Pixel_Index) return Interfaces.Unsigned_32;

   -----------
   -- Clear --
   -----------

   procedure Clear is
   begin
      for J in 0 .. Interfaces.Unsigned_32 (Width * Height - 1) loop
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
      return Pixels (Offset (X, Y));
   end Get_Pixel;

   ------------
   -- Offset --
   ------------

   function Offset
     (X : GFX.Rasteriser.Device_Pixel_Index;
      Y : GFX.Rasteriser.Device_Pixel_Index) return Interfaces.Unsigned_32 is
   begin
      return Interfaces.Unsigned_32 ((Y - Y_Min) * Width + X - X_Min);
   end Offset;

   ---------------
   -- Set_Pixel --
   ---------------

   procedure Set_Pixel
     (X     : GFX.Rasteriser.Device_Pixel_Index;
      Y     : GFX.Rasteriser.Device_Pixel_Index;
      Color : GFX.RGBA8888) is
   begin
      if X in X_Min .. X_Max and Y in Y_Min .. Y_Max then
         Pixels (Offset (X, Y)) := Color;
      end if;
   end Set_Pixel;

   --------------
   -- Set_Size --
   --------------

   procedure Set_Size
     (X      : GFX.Rasteriser.Device_Pixel_Index;
      Y      : GFX.Rasteriser.Device_Pixel_Index;
      Width  : GFX.Rasteriser.Device_Pixel_Count;
      Height : GFX.Rasteriser.Device_Pixel_Count) is
   begin
      Backing_Store.Width  := Width;
      Backing_Store.Height := Height;

      X_Min := X;
      X_Max := X + Width - 1;
      Y_Min := Y;
      Y_Max := Y + Height - 1;
   end Set_Size;

   -------------
   -- Storage --
   -------------

   function Storage return not null access Storage_Array is
   begin
      return Pixels'Unchecked_Access;
   end Storage;

end GFX.Implementation.Backing_Store;
