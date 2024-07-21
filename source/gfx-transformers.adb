--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  pragma Restrictions (No_Elaboration_Code);

pragma Ada_2022;

package body GFX.Transformers
  with Preelaborate
is

   ---------
   -- Map --
   ---------

   function Map
     (Self : GX_Transformer'Class;
      Item : GFX.Points.GF_Point) return GFX.Points.GF_Point is
   begin
      return (Item.X * Self.SX + Self.DX, Item.Y * Self.SY + Self.DY);
   end Map;

   -----------
   -- Scale --
   -----------

   procedure Scale
     (Self : in out GX_Transformer'Class;
      SX   : GFX.GX_Real;
      SY   : GFX.GX_Real) is
   begin
      Self.SX := @ * SX;
      Self.SY := @ * SY;
   end Scale;

   ------------------
   -- Set_Identity --
   ------------------

   procedure Set_Identity (Self : in out GX_Transformer'Class) is
   begin
      Self.SX := 1.0;
      Self.SY := 1.0;
      Self.DX := 0.0;
      Self.DY := 0.0;
   end Set_Identity;

   ---------------
   -- Translate --
   ---------------

   procedure Translate
     (Self : in out GX_Transformer'Class;
      DX   : GFX.GX_Real;
      DY   : GFX.GX_Real) is
   begin
      Self.DX := @ + DX;
      Self.DY := @ + DY;
   end Translate;

end GFX.Transformers;
