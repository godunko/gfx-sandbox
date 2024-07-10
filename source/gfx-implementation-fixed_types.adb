--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

package body GFX.Implementation.Fixed_Types is

   Fixed_6_Multiplier : constant := 2.0 ** 6;

   ----------------------
   -- Is_Equal_Fixed_6 --
   ----------------------

   function Is_Equal_Fixed_6
     (Left : GFX.Real; Right : GFX.Real) return Boolean is
   begin
      return To_Fixed_6 (Left) = To_Fixed_6 (Right);
      --  ??? Can it be optimized like:
      --  return Fixed_6 ((Left - Right) * Fixed_6_Multiplier) = 0;
      --  return (Left - Right) * Fixed_6_Multiplier < 1.0;
   end Is_Equal_Fixed_6;

   ----------------
   -- To_Fixed_6 --
   ----------------

   function To_Fixed_6 (Item : GFX.Real) return Fixed_6 is
   begin
      return Fixed_6 (Item * Fixed_6_Multiplier);
   end To_Fixed_6;

end GFX.Implementation.Fixed_Types;
