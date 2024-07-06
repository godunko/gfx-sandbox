--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body GFX.Implementation.Backing_Store is

   Pixel_Storage : array
     (Device_Pixel_Index range 0 .. 31,
      Device_Pixel_Index range 0 .. 31) of GFX.RGBA8888
     with Linker_Section => ".dtcm.bss";

   -----------
   -- Clear --
   -----------

   procedure Clear is
   begin
      for R in Pixel_Storage'Range (1) loop
         for C in Pixel_Storage'Range (2) loop
            Pixel_Storage (R, C) := To_RGBA (0, 0, 0, 0);
         end loop;
      end loop;
   end Clear;

   ---------------
   -- Get_Pixel --
   ---------------

   function Get_Pixel
     (X : GFX.Implementation.Device_Pixel_Index;
      Y : GFX.Implementation.Device_Pixel_Index) return GFX.RGBA8888 is
   begin
      return Pixel_Storage (Y, X);
   end Get_Pixel;

   ---------------
   -- Set_Pixel --
   ---------------

   procedure Set_Pixel
     (X     : GFX.Implementation.Device_Pixel_Index;
      Y     : GFX.Implementation.Device_Pixel_Index;
      Color : GFX.RGBA8888) is
   begin
      if X not in Pixel_Storage'Range (2)
        or Y not in Pixel_Storage'Range (1)
      then
         return;
      end if;

      Pixel_Storage (Y, X) := Color;
   end Set_Pixel;

   -------------
   -- Storage --
   -------------

   function Storage return not null access Storage_Array is
      Aux : aliased Storage_Array
        with Import, Address => Pixel_Storage'Address;

   begin
      return Aux'Unchecked_Access;
   end Storage;

end GFX.Implementation.Backing_Store;
