--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  pragma Restrictions (No_Elaboration_Code);

with GFX.Points;

package GFX.Transformers
  with Pure
is

   type GX_Transformer is tagged private
     with Preelaborable_Initialization;

   procedure Set_Identity (Self : in out GX_Transformer'Class);

   procedure Translate
     (Self : in out GX_Transformer'Class;
      DX   : GFX.GX_Real;
      DY   : GFX.GX_Real);

   procedure Scale
     (Self : in out GX_Transformer'Class;
      SX   : GFX.GX_Real;
      SY   : GFX.GX_Real);

   function Map
     (Self : GX_Transformer'Class;
      Item : GFX.Points.GF_Point) return GFX.Points.GF_Point;

private

   type GX_Transformer is tagged record
      SX : GFX.GX_Real := 1.0;
      SY : GFX.GX_Real := 1.0;
      DX : GFX.GX_Real := 0.0;
      DY : GFX.GX_Real := 0.0;
   end record;

end GFX.Transformers;
