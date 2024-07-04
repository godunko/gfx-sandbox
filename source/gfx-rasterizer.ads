--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Types;

generic
   with function Get_Pixel
     (X : A0B.Types.Unsigned_32;
      Y : A0B.Types.Unsigned_32) return GFX.RGBA8888;

   with procedure Set_Pixel
     (X     : A0B.Types.Unsigned_32;
      Y     : A0B.Types.Unsigned_32;
      Color : GFX.RGBA8888);

package GFX.Rasterizer
  --  with Pure
is

   procedure Draw_Line
     (X1, Y1, X2, Y2 : GFX.Real;
      Color          : RGBA8888);

private

   type Fixed_26_6 is new A0B.Types.Integer_32;

   function To_Fixed_26_6 (Item : GFX.Real) return Fixed_26_6;

   --  type Fixed_16_16 is new A0B.Types.Integer_32;

end GFX.Rasterizer;
