--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Draw into PPM (portable pixmap format) image and save it in file.

with A0B.Types;

package GFX.PPM is

   procedure Set_Size
     (Width : A0B.Types.Unsigned_32; Height : A0B.Types.Unsigned_32);

   procedure Set_Pixel
     (X     : A0B.Types.Unsigned_32;
      Y     : A0B.Types.Unsigned_32;
      Color : GFX.RGBA);

   function Get_Pixel
     (X : A0B.Types.Unsigned_32;
      Y : A0B.Types.Unsigned_32) return GFX.RGBA;

   procedure Save (File_Name : String);

end GFX.PPM;
