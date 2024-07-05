--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.ARMv7M.SysTick;

with GFX.Application;
with GFX.ILI9488;
with GFX.Rasterizer;

with Demo.Scene;

procedure Demo.Driver is

   package Painter is
     new GFX.Rasterizer
       (Get_Pixel => GFX.ILI9488.Get_Pixel,
        Set_Pixel => GFX.ILI9488.Set_Pixel);

   package Application is new GFX.Application (Painter, GFX.ILI9488.Set);

begin
   A0B.ARMv7M.SysTick.Initialize
     (Use_Processor_Clock => True,
      Clock_Frequency     => 168_000_000);

   GFX.ILI9488.Initialize;
   GFX.ILI9488.Enable;

   Demo.Scene.Initialize;
   Application.Run;
end Demo.Driver;
