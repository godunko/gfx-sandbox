--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

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

   begin
      Painter.Draw_Line (15.0, 50.0, 16.0, 70.0, Color);
      Painter.Draw_Line (34.5, 50.0, 35.5, 70.0, Color);
      Painter.Draw_Line (55.0, 49.5, 56.0, 69.5, Color);
      Painter.Draw_Line (74.5, 49.5, 75.5, 69.5, Color);

      Painter.Draw_Line (16.0, 80.0, 15.0, 100.0, Color);
      Painter.Draw_Line (35.5, 80.0, 34.5, 100.0, Color);
      Painter.Draw_Line (56.0, 79.5, 55.0, 99.5, Color);
      Painter.Draw_Line (75.5, 79.5, 74.5, 99.5, Color);
   end Paint;

end GFX.Widgets;
