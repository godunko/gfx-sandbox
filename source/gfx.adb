--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body GFX is

   -------------
   -- To_RGBA --
   -------------

   function To_RGBA (R, G, B, A : A0B.Types.Unsigned_8) return RGBA is
      use type A0B.Types.Unsigned_32;

      RC : constant A0B.Types.Unsigned_32 := A0B.Types.Unsigned_32 (R);
      GC : constant A0B.Types.Unsigned_32 :=
        A0B.Types.Shift_Left (A0B.Types.Unsigned_32 (G), 8);
      BC : constant A0B.Types.Unsigned_32 :=
        A0B.Types.Shift_Left (A0B.Types.Unsigned_32 (B), 8);
      AC : constant A0B.Types.Unsigned_32 :=
        A0B.Types.Shift_Left (A0B.Types.Unsigned_32 (A), 8);

   begin
      return RGBA (RC or GC or BC or AC);
   end To_RGBA;

end GFX;
