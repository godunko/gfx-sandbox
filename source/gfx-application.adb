--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with GFX.Widgets;

package body GFX.Application is

   Color : GFX.RGBA8888;

   ---------
   -- Run --
   ---------

   procedure Run is
      use type A0B.Types.Unsigned_32;

   begin
      GFX.Implementation.Root.Paint;

      for C in 0 .. 14 loop
         for R in 0 .. 9 loop
            GFX.Implementation.Backing_Store.Clear;

            for J in 0 .. GFX.Implementation.Length - 1 loop
               case GFX.Implementation.Buffer (J).Kind is
                  when GFX.Implementation.None =>
                     null;

                  when GFX.Implementation.Color =>
                     Color := GFX.Implementation.Buffer (J).Color;

                  when GFX.Implementation.Line =>
                     Rasterizer.Draw_Line
                       (GFX.Implementation.Buffer (J).X1,
                        GFX.Implementation.Buffer (J).Y1,
                        GFX.Implementation.Buffer (J).X2,
                        GFX.Implementation.Buffer (J).Y2,
                        Color);
               end case;
            end loop;

            Set
              (GFX.Implementation.Device_Point_Coordinate (C * 32),
               GFX.Implementation.Device_Point_Coordinate (R * 32),
               GFX.Implementation.Backing_Store.Storage);
         end loop;
      end loop;
   end Run;

end GFX.Application;
