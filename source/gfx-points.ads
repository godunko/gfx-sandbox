--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

package GFX.Points
  with Preelaborate
is

   type Point is record
      X : GFX.Real;
      Y : GFX.Real;
   end record;

end GFX.Points;
