--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.ARMv7M.SysTick;

with GFX.ILI9488;
with GFX.Rasterizer;

procedure Demo.Driver is

   package Painter is
     new GFX.Rasterizer
       (Get_Pixel => GFX.ILI9488.Get_Pixel,
        Set_Pixel => GFX.ILI9488.Set_Pixel);

   C : constant GFX.RGBA8888 := GFX.To_RGBA (0, 255, 0, 255);

begin
   A0B.ARMv7M.SysTick.Initialize
     (Use_Processor_Clock => True,
      Clock_Frequency     => 168_000_000);

   GFX.ILI9488.Initialize;
   GFX.ILI9488.Enable;

   Painter.Draw_Line (15.0, 50.0, 16.0, 70.0, C);
   Painter.Draw_Line (34.5, 50.0, 35.5, 70.0, C);
   Painter.Draw_Line (55.0, 49.5, 56.0, 69.5, C);
   Painter.Draw_Line (74.5, 49.5, 75.5, 69.5, C);

   Painter.Draw_Line (16.0, 80.0, 15.0, 100.0, C);
   Painter.Draw_Line (35.5, 80.0, 34.5, 100.0, C);
   Painter.Draw_Line (56.0, 79.5, 55.0, 99.5, C);
   Painter.Draw_Line (75.5, 79.5, 74.5, 99.5, C);
end Demo.Driver;
