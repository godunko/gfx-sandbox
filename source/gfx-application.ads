--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with GFX.Rasterizer;

generic
   with package Rasterizer is new GFX.Rasterizer (<>);

package GFX.Application
  --  with Preelaborate
is

   procedure Run;

end GFX.Application;
