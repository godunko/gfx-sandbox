--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

limited with GFX.Widgets;

package GFX.Implementation
  with Preelaborate
is

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
            X1, Y1, X2, Y2 : GFX.Real;
      end case;
   end record;

   Buffer : array (A0B.Types.Unsigned_32 range 0 .. 32) of Command;
   Length : A0B.Types.Unsigned_32 := 0;

end GFX.Implementation;
