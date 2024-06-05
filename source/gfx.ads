--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Interfaces;

with A0B.Types;

package GFX
  with Pure
is

   type Real is new Interfaces.IEEE_Float_32;

   type RGBA is private;

   function To_RGBA (R, G, B, A : A0B.Types.Unsigned_8) return RGBA;

private

   type RGBA is new A0B.Types.Unsigned_32;

end GFX;
