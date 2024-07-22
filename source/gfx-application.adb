--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with GFX.Implementation.Profiling; use GFX.Implementation.Profiling;

with GFX.Implementation.Snapshots;
with GFX.Points;
with GFX.Rasterizer;
with GFX.Widgets;

package body GFX.Application is

   Cycles_Rasterization : Interfaces.Unsigned_32 with Volatile;

   Screen_Horizontal_Resolution : constant := 480;
   Screen_Vertical_Resolution   : constant := 320;
   Backing_Store_Width          : constant := 64;
   Backing_Store_Height         : constant := 64;

   package Backing_Store_Rasterizer is
     new GFX.Rasterizer
       (Get_Pixel     => GFX.Implementation.Backing_Store.Get_Pixel,
        Set_Pixel     => GFX.Implementation.Backing_Store.Set_Pixel,
        Device_Width  => Screen_Horizontal_Resolution,
        Device_Height => Screen_Vertical_Resolution);

   Last_Column : constant GFX.Rasteriser.Device_Pixel_Count :=
     (Screen_Horizontal_Resolution + Backing_Store_Width - 1)
        / Backing_Store_Width - 1;
   Last_Row    : constant GFX.Rasteriser.Device_Pixel_Count :=
     (Screen_Vertical_Resolution + Backing_Store_Height - 1)
        / Backing_Store_Height - 1;

   ---------
   -- Run --
   ---------

   procedure Run is
      use type Interfaces.Unsigned_32;

      W : GFX.Rasteriser.Device_Pixel_Count;
      H : GFX.Rasteriser.Device_Pixel_Count;

   begin
      CSS_Device_Transformation (GFX.Implementation.Snapshots.CSS_To_Device);

      GFX.Implementation.Snapshots.Root.Paint;

      Start;

      for C in 0 .. Last_Column loop
         for R in 0 .. Last_Row loop
            W :=
              GFX.Rasteriser.Device_Pixel_Count'Min
                (Backing_Store_Width,
                 Screen_Horizontal_Resolution
                   - Backing_Store_Width * C);
            H :=
              GFX.Rasteriser.Device_Pixel_Count'Min
                (Backing_Store_Height,
                 Screen_Vertical_Resolution
                   - Backing_Store_Height * R);

            GFX.Implementation.Backing_Store.Set_Size
              (C * Backing_Store_Width,
               R * Backing_Store_Height,
               W,
               H);
            GFX.Implementation.Backing_Store.Clear;

            Backing_Store_Rasterizer.Set_Renderer_Clip
              (Top    => R * Backing_Store_Height,
               Left   => C * Backing_Store_Width,
               Right  => C * Backing_Store_Width + W - 1,
               Bottom => R * Backing_Store_Height + H - 1);

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
                        TL : constant GFX.Points.GF_Point :=
                          (GFX.Implementation.Snapshots.Buffer
                             (J).Clip_Region.Left,
                           GFX.Implementation.Snapshots.Buffer
                             (J).Clip_Region.Top);
                        BR : constant GFX.Points.GF_Point :=
                          (GFX.Implementation.Snapshots.Buffer
                             (J).Clip_Region.Right,
                           GFX.Implementation.Snapshots.Buffer
                             (J).Clip_Region.Bottom);

                     begin
                        Backing_Store_Rasterizer.Set_Clip
                          (Top    => TL.Y,
                           Left   => TL.X,
                           Right  => BR.X,
                           Bottom => BR.Y);
                     end;

                  when GFX.Implementation.Snapshots.Line =>
                     declare
                        S : constant GFX.Points.GF_Point :=
                          GFX.Implementation.Snapshots.Buffer (J).Start_Point;
                        E : constant GFX.Points.GF_Point :=
                          GFX.Implementation.Snapshots.Buffer (J).End_Point;

                     begin
                        Backing_Store_Rasterizer.Draw_Line (S.X, S.Y, E.X, E.Y);
                     end;
               end case;
            end loop;

            Set
              (GFX.Rasteriser.Device_Pixel_Index (C * Backing_Store_Width),
               GFX.Rasteriser.Device_Pixel_Index (R * Backing_Store_Height),
               W,
               H,
               GFX.Implementation.Backing_Store.Storage);
         end loop;
      end loop;

      Cycles_Rasterization := Cycles;
   end Run;

end GFX.Application;
