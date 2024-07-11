--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with GFX.Rasterizer;
with GFX.PPM;

procedure Test1 is

   use type GFX.Real;

   package Painter is
     new GFX.Rasterizer
     (Get_Pixel     => GFX.PPM.Get_Pixel,
      Set_Pixel     => GFX.PPM.Set_Pixel,
      Device_Width  => 130,
      Device_Height => 130);

   C : constant GFX.RGBA8888 := GFX.To_RGBA (0, 255, 0, 255);

begin
   GFX.PPM.Set_Size (130, 130);
   Painter.Set_Clip (-0.5, -0.5, 130.5, 130.5);
   Painter.Set_Settings (C, 1.0);

   Painter.Draw_Line (15.0, 50.0, 16.0, 70.0);
   Painter.Draw_Line (34.5, 50.0, 35.5, 70.0);
   Painter.Draw_Line (55.0, 49.5, 56.0, 69.5);
   Painter.Draw_Line (74.5, 49.5, 75.5, 69.5);

   Painter.Draw_Line (16.0, 80.0, 15.0, 100.0);
   Painter.Draw_Line (35.5, 80.0, 34.5, 100.0);
   Painter.Draw_Line (56.0, 79.5, 55.0, 99.5);
   Painter.Draw_Line (75.5, 79.5, 74.5, 99.5);

   GFX.PPM.Save ("out.ppm");
end Test1;
