--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with GFX.Implementation;

package body GFX.Painters is

   ---------------
   -- Draw_Line --
   ---------------

   procedure Draw_Line
     (Self           : Painter'Class;
      X1, Y1, X2, Y2 : GFX.Real;
      Color          : RGBA8888)
   is
      pragma Unreferenced (Self);

      use type A0B.Types.Unsigned_32;

   begin
      GFX.Implementation.Buffer (GFX.Implementation.Length) :=
        (Kind  => GFX.Implementation.Color,
         Color => Color);
      GFX.Implementation.Length := @ + 1;

      GFX.Implementation.Buffer (GFX.Implementation.Length) :=
        (Kind        => GFX.Implementation.Line,
         Start_Point => (X1, Y1),
         End_Point   => (X2, Y2));
      GFX.Implementation.Length := @ + 1;
   end Draw_Line;

end GFX.Painters;
