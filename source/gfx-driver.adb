--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with GFX.PPM;

procedure GFX.Driver is
begin
   GFX.PPM.Set_Size (3, 2);
   GFX.PPM.Set_Pixel (0, 0, 16#0000_00FF#);
   GFX.PPM.Set_Pixel (1, 0, 16#0000_FF00#);
   GFX.PPM.Set_Pixel (2, 0, 16#00FF_0000#);
   GFX.PPM.Set_Pixel (0, 1, 16#0000_FFFF#);
   GFX.PPM.Set_Pixel (1, 1, 16#00FF_FFFF#);
   GFX.PPM.Set_Pixel (2, 1, 16#0000_0000#);
   GFX.PPM.Save ("out.ppm");
end GFX.Driver;
