--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with GFX.Application;
with GFX.ILI9488;

package Demo.Application is new GFX.Application (GFX.ILI9488.Set);
