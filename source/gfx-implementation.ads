--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with GFX.Points;
limited with GFX.Widgets;

package GFX.Implementation
  with Preelaborate
is

   subtype Device_Point_Coordinate is A0B.Types.Integer_32;
   --  Subtype to represent device's point coordinate.

   type Widget_Access is access all GFX.Widgets.Abstract_Widget'Class;

   Root : Widget_Access;

   type Command_Kind is (None, Color, Line);

   type Command (Kind : Command_Kind := None) is record
      case Kind is
         when None =>
            null;

         when Color =>
            Color : GFX.RGBA8888;

         when Line =>
            Start_Point : GFX.Points.Point;
            End_Point   : GFX.Points.Point;
      end case;
   end record;

   Buffer : array (A0B.Types.Unsigned_32 range 0 .. 32) of Command;
   Length : A0B.Types.Unsigned_32 := 0;

end GFX.Implementation;
