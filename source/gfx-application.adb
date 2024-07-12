--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with GFX.Implementation.Snapshots;
with GFX.Points;
with GFX.Rasterizer;
with GFX.Widgets;

package body GFX.Application is

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

      T : GFX.Transformers.GX_Transformer;

   begin
      CSS_Device_Transformation (GFX.Implementation.Snapshots.CSS_To_Device);

      GFX.Implementation.Snapshots.Root.Paint;

      for C in 0 .. 14 loop
         for R in 0 .. 9 loop
            GFX.Implementation.Backing_Store.Set_Size (32, 32);
            GFX.Implementation.Backing_Store.Clear;
            T.Set_Identity;
            T.Translate (GFX.Real (-(C * 32)), GFX.Real (-(R * 32)));

            for J in 0 .. GFX.Implementation.Snapshots.Length - 1 loop
               case GFX.Implementation.Snapshots.Buffer (J).Kind is
                  when GFX.Implementation.Snapshots.None =>
                     null;

                  when GFX.Implementation.Snapshots.Settings =>
                     Backing_Store_Rasterizer.Set_Settings
                       (GFX.Implementation.Snapshots.Buffer (J).Color,
                        GFX.Implementation.Snapshots.Buffer (J).Width);

                  when GFX.Implementation.Snapshots.Clip =>
                     declare
                        TL : GFX.Points.GF_Point :=
                          (GFX.Implementation.Snapshots.Buffer
                             (J).Clip_Region.Left,
                           GFX.Implementation.Snapshots.Buffer
                             (J).Clip_Region.Top);
                        BR : GFX.Points.GF_Point :=
                          (GFX.Implementation.Snapshots.Buffer
                             (J).Clip_Region.Right,
                           GFX.Implementation.Snapshots.Buffer
                             (J).Clip_Region.Bottom);

                     begin
                        TL := T.Map (TL);
                        BR := T.Map (BR);

                        Backing_Store_Rasterizer.Set_Clip
                          (Top    => TL.Y,
                           Left   => TL.X,
                           Right  => BR.X,
                           Bottom => BR.Y);
                     end;

                  when GFX.Implementation.Snapshots.Line =>
                     declare
                        S : GFX.Points.GF_Point :=
                          GFX.Implementation.Snapshots.Buffer (J).Start_Point;
                        E : GFX.Points.GF_Point :=
                          GFX.Implementation.Snapshots.Buffer (J).End_Point;

                     begin
                        S := T.Map (S);
                        E := T.Map (E);

                        Backing_Store_Rasterizer.Draw_Line (S.X, S.Y, E.X, E.Y);
                     end;
               end case;
            end loop;

            Set
              (GFX.Implementation.Device_Pixel_Index (C * 32),
               GFX.Implementation.Device_Pixel_Index (R * 32),
               GFX.Implementation.Backing_Store.Storage,
               GFX.Implementation.Backing_Store.Storage_Size);
         end loop;
      end loop;
   end Run;

end GFX.Application;
