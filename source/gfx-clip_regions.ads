--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

package GFX.Clip_Regions
  with Pure
is

   type GX_Clip_Region is record
      Top    : GFX.GX_Real;
      Left   : GFX.GX_Real;
      Right  : GFX.GX_Real;
      Bottom : GFX.GX_Real;
   end record;

end GFX.Clip_Regions;
