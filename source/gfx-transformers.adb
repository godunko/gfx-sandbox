--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

pragma Ada_2022;

package body GFX.Transformers
  with Preelaborate
is

   ---------
   -- Map --
   ---------

   function Map
     (Self : Transformer'Class;
      Item : Point) return Point is
   begin
      return (Item.X + Self.DX, Item.Y + Self.DY);
   end Map;

   ------------------
   -- Set_Identity --
   ------------------

   procedure Set_Identity (Self : in out Transformer'Class) is
   begin
      Self.DX := 0.0;
      Self.DY := 0.0;
   end Set_Identity;

   ---------------
   -- Translate --
   ---------------

   procedure Translate
     (Self : in out Transformer'Class;
      DX   : GFX.Real;
      DY   : GFX.Real) is
   begin
      Self.DX := @ + DX;
      Self.DY := @ + DY;
   end Translate;

end GFX.Transformers;
