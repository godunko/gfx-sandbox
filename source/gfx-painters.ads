--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with GFX.Clip_Regions;
with GFX.Transformers;

package GFX.Painters
  with Preelaborate
is

   type Painter is tagged limited private;

   procedure Draw_Line
     (Self           : in out Painter'Class;
      X1, Y1, X2, Y2 : GFX.Real);

   procedure Set_Color (Self : in out Painter'Class; To : GFX.RGBA8888);

   procedure Set_Width (Self : in out Painter'Class; To : GFX.Real);

   procedure Set_Transformation
     (Self : in out Painter'Class;
      To   : GFX.Transformers.Transformer);

   procedure Set_Clip_Region
     (Self : in out Painter'Class;
      To   : GFX.Clip_Regions.GX_Clip_Region);

private

   type Painter is tagged limited record
      Color_Value        : GFX.RGBA8888 := 0;
      Width_Value        : GFX.Real     := 1.0;
      Settings_Stored    : Boolean      := False;
      Transformation     : GFX.Transformers.Transformer;
      Clip_Region_Value  : GFX.Clip_Regions.GX_Clip_Region;
      Clip_Region_Stored : Boolean      := False;
   end record;

end GFX.Painters;
