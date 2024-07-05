--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with GFX.Points;

package GFX.Transformers
  with Preelaborate
is

   type Transformer is tagged limited private
     with Preelaborable_Initialization;

   procedure Translate
     (Self : in out Transformer'Class;
      DX   : GFX.Real;
      DY   : GFX.Real);

   procedure Set_Identity (Self : in out Transformer'Class);

   function Map
     (Self : Transformer'Class;
      Item : GFX.Points.Point) return GFX.Points.Point;

private

   type Transformer is tagged limited record
      DX : GFX.Real := 0.0;
      DY : GFX.Real := 0.0;
   end record;

end GFX.Transformers;
