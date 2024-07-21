--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Types;

with GFX.Clip_Regions;
with GFX.Points;
with GFX.Transformers;
limited with GFX.Widgets;

package GFX.Implementation.Snapshots
  with Preelaborate
is

   type Widget_Access is access all GFX.Widgets.Abstract_Widget'Class;

   Root          : Widget_Access;
   CSS_To_Device : GFX.Transformers.GX_Transformer;

   type Command_Kind is (None, Settings, Clip, Line);

   type Command (Kind : Command_Kind := None) is record
      case Kind is
         when None =>
            null;

         when Settings =>
            Color : GFX.RGBA8888;
            Width : GFX.GX_Real;

         when Clip =>
            Clip_Region : GFX.Clip_Regions.GX_Clip_Region;

         when Line =>
            Start_Point : GFX.Points.GF_Point;
            End_Point   : GFX.Points.GF_Point;
      end case;
   end record;

   Buffer : array (A0B.Types.Unsigned_32 range 0 .. 1023) of Command
     with Linker_Section => ".dtcm.bss";
   Length : A0B.Types.Unsigned_32 := 0
     with Linker_Section => ".dtcm.data";

end GFX.Implementation.Snapshots;
