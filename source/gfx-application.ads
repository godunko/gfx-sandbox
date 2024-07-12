--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with GFX.Implementation.Backing_Store;
with GFX.Transformers;

generic
   with procedure Set
     (X : GFX.Implementation.Device_Pixel_Index;
      Y : GFX.Implementation.Device_Pixel_Index;
      S : not null access GFX.Implementation.Backing_Store.Storage_Array;
      C : GFX.Implementation.Device_Pixel_Count);

   with procedure CSS_Device_Transformation
     (Transformation : out GFX.Transformers.GX_Transformer);

package GFX.Application
  --  with Preelaborate
is

   procedure Run;

end GFX.Application;
