--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with GFX.Implementation;
with GFX.Painters;

package body GFX.Widgets is

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Self   : out Abstract_Widget'Class;
      Width  : A0B.Types.Integer_32;
      Height : A0B.Types.Integer_32) is
   begin
      GFX.Implementation.Root := Self'Unchecked_Access;
   end Initialize;

   -----------
   -- Paint --
   -----------

   not overriding procedure Paint (Self : in out Abstract_Widget) is
      Painter : GFX.Painters.Painter;
      Color   : constant GFX.RGBA8888 := GFX.To_RGBA (0, 255, 0, 255);
      X       : GFX.Real;
      Y       : GFX.Real;

   begin
      Painter.Set_Color (Color);

      Y := 50.0;
      X := 0.0;

      for J in 1 .. 50 loop
         Painter.Draw_Line (X, Y, X + 4.5, Y);
         Painter.Draw_Line (X + 4.5, Y, X + 5.5, Y + 20.0);
         Painter.Draw_Line (X + 5.5, Y + 20.0, X + 9.0, Y + 20.0);
         Painter.Draw_Line (X + 9.0, Y + 20.0, X + 10.0, Y);

         X := @ + 10.0;
      end loop;

      Y := 75.0;
      X := 0.0;

      for J in 1 .. 25 loop
         Painter.Draw_Line (X, Y, X + 9.5, Y);
         Painter.Draw_Line (X + 9.5, Y, X + 10.5, Y + 20.0);
         Painter.Draw_Line (X + 10.5, Y + 20.0, X + 19.0, Y + 20.0);
         Painter.Draw_Line (X + 19.0, Y + 20.0, X + 20.0, Y);

         X := @ + 20.0;
      end loop;

      Y := 100.0;
      X := 0.0;

      for J in 1 .. 17 loop
         Painter.Draw_Line (X, Y, X + 14.5, Y);
         Painter.Draw_Line (X + 14.5, Y, X + 15.5, Y + 20.0);
         Painter.Draw_Line (X + 15.5, Y + 20.0, X + 29.0, Y + 20.0);
         Painter.Draw_Line (X + 29.0, Y + 20.0, X + 30.0, Y);

         X := @ + 30.0;
      end loop;

      Y := 125.0;
      X := 0.0;

      for J in 1 .. 12 loop
         Painter.Draw_Line (X, Y, X + 19.5, Y);
         Painter.Draw_Line (X + 19.5, Y, X + 20.5, Y + 20.0);
         Painter.Draw_Line (X + 20.5, Y + 20.0, X + 39.0, Y + 20.0);
         Painter.Draw_Line (X + 39.0, Y + 20.0, X + 40.0, Y);

         X := @ + 40.0;
      end loop;
   end Paint;

end GFX.Widgets;
