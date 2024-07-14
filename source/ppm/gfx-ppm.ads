--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Draw into PPM (portable pixmap format) image and save it in file.

with A0B.Types;

with GFX.Implementation;

package GFX.PPM is

   procedure Set_Size
     (Width : A0B.Types.Unsigned_32; Height : A0B.Types.Unsigned_32);

   procedure Set_Pixel
     (X     : GFX.Implementation.Device_Pixel_Index;
      Y     : GFX.Implementation.Device_Pixel_Index;
      Color : GFX.RGBA8888);

   function Get_Pixel
     (X : GFX.Implementation.Device_Pixel_Index;
      Y : GFX.Implementation.Device_Pixel_Index) return GFX.RGBA8888;

   procedure Save (File_Name : String);

end GFX.PPM;
