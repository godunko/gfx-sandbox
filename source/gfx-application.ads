--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with GFX.Implementation.Backing_Store;

generic
   with procedure Set
     (X : GFX.Implementation.Device_Point_Coordinate;
      Y : GFX.Implementation.Device_Point_Coordinate;
      S : not null access GFX.Implementation.Backing_Store.Storage_Array);

package GFX.Application
  --  with Preelaborate
is

   procedure Run;

end GFX.Application;
