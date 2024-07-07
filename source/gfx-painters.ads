--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with GFX.Transformers;

package GFX.Painters
  with Preelaborate
is

   type Painter is tagged limited private;

   procedure Draw_Line
     (Self           : in out Painter'Class;
      X1, Y1, X2, Y2 : GFX.Real);

   procedure Set_Color (Self : in out Painter'Class; Color : GFX.RGBA8888);

   procedure Set_Transformation
     (Self : in out Painter'Class;
      To   : GFX.Transformers.Transformer);

private

   type Painter is tagged limited record
      Color_Value    : GFX.RGBA8888 := 0;
      Color_Stored   : Boolean := False;
      Transformation : GFX.Transformers.Transformer;
   end record;

end GFX.Painters;
