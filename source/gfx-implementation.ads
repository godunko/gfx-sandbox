--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with GFX.Clip_Regions;
with GFX.Points;
limited with GFX.Widgets;

package GFX.Implementation
  with Preelaborate
is

   subtype Device_Pixel_Index is A0B.Types.Integer_32;
   --  Index of the device's hardware pixel.

   subtype Device_Pixel_Coordinate is GFX.Real;
   --  Coordinate of the device's hardware pixel. Integral value corresponds to
   --  the center of the hardware pixel.

   type Widget_Access is access all GFX.Widgets.Abstract_Widget'Class;

   Root : Widget_Access;

   type Command_Kind is (None, Color, Clip, Line);

   type Command (Kind : Command_Kind := None) is record
      case Kind is
         when None =>
            null;

         when Color =>
            Color : GFX.RGBA8888;

         when Clip =>
            Clip_Region : GFX.Clip_Regions.GX_Clip_Region;

         when Line =>
            Start_Point : GFX.Points.GF_Point;
            End_Point   : GFX.Points.GF_Point;
      end case;
   end record;

   Buffer : array (A0B.Types.Unsigned_32 range 0 .. 1023) of Command
     with Linker_Section => ".dtcm.bss";
   Length : A0B.Types.Unsigned_32 := 0
     with Linker_Section => ".dtcm.data";

end GFX.Implementation;
