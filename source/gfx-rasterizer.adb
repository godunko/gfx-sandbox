--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with Ada.Unchecked_Conversion;

package body GFX.Rasterizer is

   subtype Fixed_16_16 is A0B.Types.Integer_32;

   function To_Fixed_16_16_Div
     (V : A0B.Types.Integer_32;
      D : A0B.Types.Integer_32) return Fixed_16_16;
   --  Converts integer value D to Fixed_16_16 format and divide it into
   --  integer number D.
   --
   --  It uses 64-bit ariphmetic to extend range.

   function Shift_Left
     (Item   : A0B.Types.Integer_32;
      Amount : Natural) return A0B.Types.Integer_32;

   function Shift_Right_Arithmetic
     (Item   : A0B.Types.Integer_32;
      Amount : Natural) return A0B.Types.Integer_32;

   function "and"
     (Left  : A0B.Types.Integer_32;
      Right : A0B.Types.Unsigned_32) return A0B.Types.Integer_32;

   function "xor"
     (Left  : A0B.Types.Integer_32;
      Right : A0B.Types.Unsigned_32) return A0B.Types.Integer_32;

   -----------
   -- "and" --
   -----------

   function "and"
     (Left  : A0B.Types.Integer_32;
      Right : A0B.Types.Unsigned_32) return A0B.Types.Integer_32
   is
      use type A0B.Types.Unsigned_32;

      function To_Unsigned_32 is
        new Ada.Unchecked_Conversion
             (A0B.Types.Integer_32, A0B.Types.Unsigned_32);

      function To_Integer_32 is
        new Ada.Unchecked_Conversion
             (A0B.Types.Unsigned_32, A0B.Types.Integer_32);

   begin
      return To_Integer_32 (To_Unsigned_32 (Left) and Right);
   end "and";

   function "xor"
     (Left  : A0B.Types.Integer_32;
      Right : A0B.Types.Unsigned_32) return A0B.Types.Integer_32
   is
      use type A0B.Types.Unsigned_32;

      function To_Unsigned_32 is
        new Ada.Unchecked_Conversion
             (A0B.Types.Integer_32, A0B.Types.Unsigned_32);

      function To_Integer_32 is
        new Ada.Unchecked_Conversion
             (A0B.Types.Unsigned_32, A0B.Types.Integer_32);

   begin
      return To_Integer_32 (To_Unsigned_32 (Left) xor Right);
   end "xor";

   ---------------
   -- Draw_Line --
   ---------------

   procedure Draw_Line
     (X1    : GFX.Implementation.Device_Pixel_Coordinate;
      Y1    : GFX.Implementation.Device_Pixel_Coordinate;
      X2    : GFX.Implementation.Device_Pixel_Coordinate;
      Y2    : GFX.Implementation.Device_Pixel_Coordinate;
      Color : GFX.RGBA8888)
   is
      use A0B.Types;
      use type A0B.Types.Integer_32;

      function "*" (Left : RGBA8888; Right : A0B.Types.Integer_32) return RGBA8888
        with Pre => Right in 0 .. 255;

      function Blend (V : RGBA8888; C : RGBA8888) return RGBA8888;

      procedure Draw_Pixel
        (X : A0B.Types.Integer_32;
         Y : A0B.Types.Integer_32;
         A : A0B.Types.Integer_32);

      ---------
      -- "*" --
      ---------

      function "*" (Left : RGBA8888; Right : A0B.Types.Integer_32) return RGBA8888 is
         use type A0B.Types.Unsigned_32;

         RB : A0B.Types.Unsigned_32 := A0B.Types.Unsigned_32 (Left);
         GA : A0B.Types.Unsigned_32 :=
           A0B.Types.Shift_Right (A0B.Types.Unsigned_32 (Left), 8);

      begin
         RB := @  and 16#00FF_00FF#;
         RB := @ * Unsigned_32 (Right);
         RB := @ + (Shift_Right (@, 8) and 16#00FF_00FF#);
         RB := @ + 16#0080_0080#;
         RB := @ and 16#FF00_FF00#;

         GA := @  and 16#00FF_00FF#;
         GA := @ * Unsigned_32 (Right);
         GA := @ + (Shift_Right (@, 8) and 16#00FF_00FF#);
         GA := @ + 16#0080_0080#;
         GA := @ and 16#FF00_FF00#;

         return RGBA8888 (A0B.Types.Shift_Right (RB, 8) or GA);
      end "*";

      -----------
      -- Blend --
      -----------

      function Blend (V : RGBA8888; C : RGBA8888) return RGBA8888 is
         use type A0B.Types.Unsigned_32;

      begin
         return
           C + V * A0B.Types.Integer_32
             (A0B.Types.Shift_Right (not A0B.Types.Unsigned_32 (C), 24));
      end Blend;

      ----------------
      -- Draw_Pixel --
      ----------------

      procedure Draw_Pixel
        (X : A0B.Types.Integer_32;
         Y : A0B.Types.Integer_32;
         A : A0B.Types.Integer_32)
      is
         XU : constant GFX.Implementation.Device_Pixel_Index :=
           GFX.Implementation.Device_Pixel_Index (X);
         YU : constant GFX.Implementation.Device_Pixel_Index :=
           GFX.Implementation.Device_Pixel_Index (Y);
         C  : constant RGBA8888 := Color * A;

      begin
         if X >= 0 and X < Device_Width
           and Y >= 0 and Y < Device_Height
         then
            Set_Pixel (XU, YU, Blend (Get_Pixel (XU, YU), C));
         end if;
      end Draw_Pixel;

      --  Digital Differential Analyzer (DDA) algorithm is used to draw
      --  line. Fixed point 16.16 format is used to improve floating point
      --  interpolation rounding errors on screens with less than 32k pixels
      --  per line/column.
      --
      --  8 most significant bits of the fractional part is used as intensity
      --  value for the antialiasing.
      --
      --  Real numbers are mapped onto 64x64 subpixels first, zero fractional
      --  part of the number is a center of the subpixel matrix. It is not
      --  obvious, due to manual optimization of the code, but it is an
      --  important property.

      Xi1 : constant A0B.Types.Integer_32 := A0B.Types.Integer_32 (X1 * 64.0);
      Yi1 : constant A0B.Types.Integer_32 := A0B.Types.Integer_32 (Y1 * 64.0);
      Xi2 : A0B.Types.Integer_32 := A0B.Types.Integer_32 (X2 * 64.0);
      Yi2 : A0B.Types.Integer_32 := A0B.Types.Integer_32 (Y2 * 64.0);
      --  Map float point coordinates to subpixels.

      DX  : constant A0B.Types.Integer_32 := Xi2 - Xi1;
      DY  : constant A0B.Types.Integer_32 := Yi2 - Yi1;

      A    : A0B.Types.Integer_32;
      AS   : A0B.Types.Integer_32;
      AE   : A0B.Types.Integer_32;

   begin
      if abs DX < abs DY then
         declare
            Y    : A0B.Types.Integer_32;
            YS   : A0B.Types.Integer_32;
            X    : Fixed_16_16;
            Xinc : Fixed_16_16;

         begin
            Xinc := To_Fixed_16_16_Div (DX, DY);

            if Yi1 > Yi2 then
               raise Program_Error;
            end if;

            X := Shift_Left (Xi1, 10);
            X := @ + Shift_Right_Arithmetic (((Yi1 and 16#3F#)) * Xinc, 6);
            --  Minor correction of the X by position of the Y inside subpixel
            --  matrix.

            X   := @ - Xinc / 2;
            Yi2 := @ + 63;
            --  Adjustment of the position of the line's ends to occupy
            --  half of the pixel more in each direction. Adjustment of
            --  the starting point is done too, but optimized out.

            Y  := Shift_Right_Arithmetic (Yi1, 6);
            YS := Shift_Right_Arithmetic (Yi2, 6);

            if Y = YS then
               AS := Yi2 - Yi1;
               AE := 0;

            else
               AS := 64 - (Yi1 and 16#3F#);
               AE := Yi2 and 16#3F#;
            end if;

            --  Draw the first pixel of the line

            A := Shift_Right_Arithmetic (X, 8) and 16#FF#;
            Draw_Pixel
              (Shift_Right_Arithmetic (X, 16),
               Y,
               Shift_Right_Arithmetic ((A xor 16#FF#) * AS, 6));
            Draw_Pixel
              (Shift_Right_Arithmetic (X, 16) + 1,
               Y,
               Shift_Right_Arithmetic (A * AS, 6));

            X := @ + Xinc;
            Y := @ + 1;

            while Y < YS loop
               A := Shift_Right_Arithmetic (X, 8) and 16#FF#;
               Draw_Pixel (Shift_Right_Arithmetic (X, 16), Y, A xor 16#FF#);
               Draw_Pixel (Shift_Right_Arithmetic (X, 16) + 1, Y, A);

               X := @ + Xinc;
               Y := @ + 1;
            end loop;

            --  Draw the last pixel of the line

            A := Shift_Right_Arithmetic (X, 8) and 16#FF#;
            Draw_Pixel
              (Shift_Right_Arithmetic (X, 16),
               Y,
               Shift_Right_Arithmetic ((A xor 16#FF#) * AE, 6));
            Draw_Pixel
              (Shift_Right_Arithmetic (X, 16) + 1,
               Y,
               Shift_Right_Arithmetic (A * AE, 6));
         end;

      else
         if DX = 0 then
            return;
         end if;

         declare
            X    : A0B.Types.Integer_32;
            XS   : A0B.Types.Integer_32;
            Y    : Fixed_16_16;
            Yinc : Fixed_16_16;

         begin
            Yinc := To_Fixed_16_16_Div (DY, DX);

            if Xi1 > Xi2 then
               raise Program_Error;
            end if;

            Y := Shift_Left (Yi1, 10);
            Y := @ + Shift_Right_Arithmetic (((Xi1 and 16#3F#)) * Yinc, 6);

            Y   := @ - Yinc / 2;
            Xi2 := @ + 63;

            X  := Shift_Right_Arithmetic (Xi1, 6);
            XS := Shift_Right_Arithmetic (Xi2, 6);

            if X = XS then
               AS := Xi2 - Xi1;
               AE := 0;

            else
               AS := 64 - (Xi1 and 16#3F#);
               AE := Xi2 and 16#3F#;
            end if;

            A := Shift_Right_Arithmetic (Y, 8) and 16#FF#;
            Draw_Pixel
              (X,
               Shift_Right_Arithmetic (Y, 16),
               Shift_Right_Arithmetic ((A xor 16#FF#) * AS, 6));
            Draw_Pixel
              (X,
               Shift_Right_Arithmetic (Y, 16) + 1,
               Shift_Right_Arithmetic (A * AS, 6));

            Y := @ + Yinc;
            X := @ + 1;

            while X < XS loop
               A := Shift_Right_Arithmetic (Y, 8) and 16#FF#;
               Draw_Pixel (X, Shift_Right_Arithmetic (Y, 16), A xor 16#FF#);
               Draw_Pixel (X, Shift_Right_Arithmetic (Y, 16) + 1, A);

               Y := @ + Yinc;
               X := @ + 1;
            end loop;

            A := Shift_Right_Arithmetic (Y, 8) and 16#FF#;
            Draw_Pixel
              (X,
               Shift_Right_Arithmetic (Y, 16),
               Shift_Right_Arithmetic ((A xor 16#FF#) * AE, 6));
            Draw_Pixel
              (X,
               Shift_Right_Arithmetic (Y, 16) + 1,
               Shift_Right_Arithmetic (A * AE, 6));
         end;
      end if;
   end Draw_Line;

   ----------------
   -- Shift_Left --
   ----------------

   function Shift_Left
     (Item   : A0B.Types.Integer_32;
      Amount : Natural) return A0B.Types.Integer_32
   is
      function To_Unsigned_32 is
        new Ada.Unchecked_Conversion
             (A0B.Types.Integer_32, A0B.Types.Unsigned_32);

      function To_Integer_32 is
        new Ada.Unchecked_Conversion
             (A0B.Types.Unsigned_32, A0B.Types.Integer_32);

   begin
      return
        To_Integer_32 (A0B.Types.Shift_Left (To_Unsigned_32 (Item), Amount));
   end Shift_Left;

   ----------------------------
   -- Shift_Right_Arithmetic --
   ----------------------------

   function Shift_Right_Arithmetic
     (Item   : A0B.Types.Integer_32;
      Amount : Natural) return A0B.Types.Integer_32
   is
      function To_Unsigned_32 is
        new Ada.Unchecked_Conversion
             (A0B.Types.Integer_32, A0B.Types.Unsigned_32);

      function To_Integer_32 is
        new Ada.Unchecked_Conversion
             (A0B.Types.Unsigned_32, A0B.Types.Integer_32);

   begin
      return
        To_Integer_32
          (A0B.Types.Shift_Right_Arithmetic (To_Unsigned_32 (Item), Amount));
   end Shift_Right_Arithmetic;

   ------------------------
   -- To_Fixed_16_16_Div --
   ------------------------

   function To_Fixed_16_16_Div
     (V : A0B.Types.Integer_32;
      D : A0B.Types.Integer_32) return Fixed_16_16
   is
      use type A0B.Types.Integer_64;

      function To_Integer_64 is
        new Ada.Unchecked_Conversion
              (A0B.Types.Unsigned_64, A0B.Types.Integer_64);

      function To_Unsigned_64 is
        new Ada.Unchecked_Conversion
              (A0B.Types.Integer_64, A0B.Types.Unsigned_64);

      V64   : constant A0B.Types.Integer_64  := A0B.Types.Integer_64 (V);
      V64B  : constant A0B.Types.Unsigned_64 := To_Unsigned_64 (V64);
      V64FB : constant A0B.Types.Unsigned_64 :=
        A0B.Types.Shift_Left (V64B, 16);
      V64F  : constant A0B.Types.Integer_64  := To_Integer_64 (V64FB);

   begin
      return A0B.Types.Integer_32 (V64F / A0B.Types.Integer_64 (D));
   end To_Fixed_16_16_Div;

   -------------------
   -- To_Fixed_26_6 --
   -------------------

   function To_Fixed_26_6 (Item : GFX.Real) return Fixed_26_6 is
   begin
      return Fixed_26_6 (Item * 64.0);
   end To_Fixed_26_6;

end GFX.Rasterizer;
