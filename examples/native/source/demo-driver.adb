--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  with GFX.Rasterizer;
--  with GFX.PPM;
--
--  with GFX.Implementation.Fixed_Types;
--  with GFX.Widgets;

with Demo.Application;
with Demo.PPM_Display;
with Demo.Scene;

procedure Demo.Driver is
   --
   --  use GFX;
   --  use GFX.Implementation.Fixed_Types;
   --
   --  LBN : Fixed_16 with Volatile;
   --  UBN : Fixed_16 with Volatile;
   --  LBZ : Fixed_16 with Volatile;
   --  UBZ : Fixed_16 with Volatile;
   --  LBP : Fixed_16 with Volatile;
   --  UBP : Fixed_16 with Volatile;
   --
   --  procedure Test_Fixed_16 is
   --  begin
   --     LBN := Pixel_Lower_Bound (-1);
   --     UBN := Pixel_Upper_Bound (-1);
   --     LBZ := Pixel_Lower_Bound (0);
   --     UBZ := Pixel_Upper_Bound (0);
   --     LBP := Pixel_Lower_Bound (1);
   --     UBP := Pixel_Upper_Bound (1);
   --  end Test_Fixed_16;
   --
   --  package Painter is
   --    new GFX.Rasterizer
   --      (Get_Pixel     => GFX.PPM.Get_Pixel,
   --       Set_Pixel     => GFX.PPM.Set_Pixel,
   --       Device_Width  => 800,
   --       Device_Height => 480);
   --
   --  Color : constant GFX.RGBA8888 := GFX.To_RGBA (0, 255, 0, 255);

begin
   Demo.PPM_Display.Initialize;

   Demo.Scene.Initialize;
   Demo.Application.Run;
   --  Test_Fixed_16;

   --  GFX.PPM.Set_Size (800, 480);
   --  --  GFX.PPM.Set_Pixel (0, 0, 16#0000_00FF#);
   --  --  GFX.PPM.Set_Pixel (1, 0, 16#0000_FF00#);
   --  --  GFX.PPM.Set_Pixel (2, 0, 16#00FF_0000#);
   --  --  GFX.PPM.Set_Pixel (0, 1, 16#0000_FFFF#);
   --  --  GFX.PPM.Set_Pixel (1, 1, 16#00FF_FFFF#);
   --  --  GFX.PPM.Set_Pixel (2, 1, 16#0000_0000#);
   --
   --  Painter.Set_Settings (Color, 1.0);
   --  Painter.Draw_Line (10.0, 50.0, 15.0, 50.0);
   --  Painter.Draw_Line (16.0, 70.0, 21.0, 70.0);
   --
   --  Painter.Draw_Line (15.0, 50.0, 16.0, 70.0);
   --  Painter.Draw_Line (34.5, 50.0, 35.5, 70.0);
   --  Painter.Draw_Line (55.0, 49.5, 56.0, 69.5);
   --  Painter.Draw_Line (74.5, 49.5, 75.5, 69.5);
   --
   --  Painter.Draw_Line (16.0, 80.0, 15.0, 100.0);
   --  Painter.Draw_Line (35.5, 80.0, 34.5, 100.0);
   --  Painter.Draw_Line (56.0, 79.5, 55.0, 99.5);
   --  Painter.Draw_Line (75.5, 79.5, 74.5, 99.5);
   --
   --  --  GFX.Painter.Draw_Line (100.0, 50.0, 300.0, 190.0, 16#00FFFFFF#);

   Demo.PPM_Display.Screenshot ("out.ppm");
end Demo.Driver;
