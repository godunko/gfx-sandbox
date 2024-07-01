--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  ILI9488 320x480 SPI display

with A0B.Types;

package GFX.ILI9488 is

   procedure Set_Pixel
     (X     : A0B.Types.Unsigned_32;
      Y     : A0B.Types.Unsigned_32;
      Color : GFX.RGBA8888);

   function Get_Pixel
     (X : A0B.Types.Unsigned_32;
      Y : A0B.Types.Unsigned_32) return GFX.RGBA8888;

   procedure Initialize;

   procedure Enable;

end GFX.ILI9488;
