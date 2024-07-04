--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package GFX.Painters
  with Preelaborate
is

   type Painter is tagged limited private;

   procedure Draw_Line
     (Self           : Painter'Class;
      X1, Y1, X2, Y2 : GFX.Real;
      Color          : RGBA8888);

private

   type Painter is tagged limited null record;

end GFX.Painters;
