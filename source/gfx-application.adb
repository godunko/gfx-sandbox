--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with GFX.Points;
with GFX.Rasterizer;
with GFX.Transformers;
with GFX.Widgets;

package body GFX.Application is

   Color : GFX.RGBA8888;

   package Backing_Store_Rasterizer is
     new GFX.Rasterizer
       (Get_Pixel     => GFX.Implementation.Backing_Store.Get_Pixel,
        Set_Pixel     => GFX.Implementation.Backing_Store.Set_Pixel,
        Device_Width  => 32,
        Device_Height => 32);

   ---------
   -- Run --
   ---------

   procedure Run is
      use type A0B.Types.Unsigned_32;

      T : GFX.Transformers.Transformer;

   begin
      GFX.Implementation.Root.Paint;

      for C in 0 .. 14 loop
         for R in 0 .. 9 loop
            GFX.Implementation.Backing_Store.Clear;
            T.Set_Identity;
            T.Translate (GFX.Real (-(C * 32)), GFX.Real (-(R * 32)));

            for J in 0 .. GFX.Implementation.Length - 1 loop
               case GFX.Implementation.Buffer (J).Kind is
                  when GFX.Implementation.None =>
                     null;

                  when GFX.Implementation.Color =>
                     Color := GFX.Implementation.Buffer (J).Color;

                  when GFX.Implementation.Line =>
                     declare
                        S : GFX.Points.Point :=
                          GFX.Implementation.Buffer (J).Start_Point;
                        E : GFX.Points.Point :=
                          GFX.Implementation.Buffer (J).End_Point;

                     begin
                        S := T.Map (S);
                        E := T.Map (E);

                        Backing_Store_Rasterizer.Draw_Line
                          (S.X, S.Y, E.X, E.Y, Color);
                     end;
               end case;
            end loop;

            Set
              (GFX.Implementation.Device_Pixel_Index (C * 32),
               GFX.Implementation.Device_Pixel_Index (R * 32),
               GFX.Implementation.Backing_Store.Storage);
         end loop;
      end loop;
   end Run;

end GFX.Application;
