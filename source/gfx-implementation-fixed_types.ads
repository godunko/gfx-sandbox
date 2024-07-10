--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This package contains type declarations and operations for binary fixed
--  point types with 6 and 16 bits of the precision used for rasterizing.
--
--  They use Integer_32 as base type, which is enough to support displays with
--  reasonable size for modern 32-bit MCUs. On 64bit systems Integer_64 can be
--  used as base type to enhance range of supported display resolutions, and/or
--  improve performance.

pragma Restrictions (No_Elaboration_Code);

with Interfaces;

package GFX.Implementation.Fixed_Types
  with Preelaborate
is

   type Fixed_6 is private;

   type Fixed_16 is private;

   function To_Fixed_6 (Item : GFX.Real) return Fixed_6;
   --  Convert given floating point value to binary fixed point value with 6
   --  bits of precision.

   function Is_Equal_Fixed_6 (Left : GFX.Real; Right : GFX.Real) return Boolean;
   --  Return True when two given values is equal when converted to Fixed_6
   --  type.
   --
   --  ??? Float->Integer conversion is expensive on ARMv7M, can it be
   --  optimized ???

private

   type Fixed_6 is new Interfaces.Integer_32;

   type Fixed_16 is new Interfaces.Integer_32;

end GFX.Implementation.Fixed_Types;
