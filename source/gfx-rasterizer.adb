--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with Ada.Unchecked_Conversion;

with GFX.Drawing.Primitive_Rasterizer;
with GFX.Points;

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

   function Integral (Item : Fixed_16_16) return GFX.Drawing.Device_Pixel_Index;

   function "and"
     (Left  : A0B.Types.Integer_32;
      Right : A0B.Types.Unsigned_32) return A0B.Types.Integer_32;

   function "xor"
     (Left  : A0B.Types.Integer_32;
      Right : A0B.Types.Unsigned_32) return A0B.Types.Integer_32;

   function Clip_Line
     (X1 : in out GFX.Real;
      Y1 : in out GFX.Real;
      X2 : in out GFX.Real;
      Y2 : in out GFX.Real) return Boolean;
   --  Clip line to the area one pixel wider in all directions than device area.

   Xmin : GFX.Real with Volatile;
   Xmax : GFX.Real with Volatile;
   Ymin : GFX.Real with Volatile;
   Ymax : GFX.Real with Volatile;

   Xd_Min : GFX.Drawing.Device_Pixel_Index with Volatile;
   Xd_Max : GFX.Drawing.Device_Pixel_Index with Volatile;
   Yd_Min : GFX.Drawing.Device_Pixel_Index with Volatile;
   Yd_Max : GFX.Drawing.Device_Pixel_Index with Volatile;

   Color : GFX.RGBA8888;
   Width : GFX.Real;

   procedure Fill_Span
     (X        : GFX.Drawing.Device_Pixel_Index;
      Y        : GFX.Drawing.Device_Pixel_Index;
      Width    : GFX.Drawing.Device_Pixel_Count;
      Coverage : GFX.Drawing.Grayscale);

   procedure Draw_Thick_Line
     (A : GFX.Points.GF_Point;
      B : GFX.Points.GF_Point);
   --  Draw straight line between given two points of the given width. It
   --  supports anti-aliasing.

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
   -- Clip_Line --
   ---------------

   function Clip_Line
     (X1 : in out GFX.Real;
      Y1 : in out GFX.Real;
      X2 : in out GFX.Real;
      Y2 : in out GFX.Real) return Boolean is
   begin
      if X1 < Xmin then
         if X2 <= Xmin then
            return True;
         end if;

         Y1 := @ + (Y2 - Y1) / (X2 - X1) * (Xmin - X1);
         X1 := Xmin;

      elsif X1 > Xmax then
         if X2 >= Xmax then
            return True;
         end if;

         Y1 := @ + (Y2 - Y1) / (X2 - X1) * (Xmax - X1);
         X1 := Xmax;
      end if;

      if X2 < Xmin then
         Y2 := @ + (Y2 - Y1) / (X2 - X1) * (Xmin - X2);
         X2 := Xmin;

      elsif X2 > Xmax then
         Y2 := @ + (Y2 - Y1) / (X2 - X1) * (Xmax - X2);
         X2 := Xmax;
      end if;

      if Y1 < Ymin then
         if Y2 <= Ymin then
            return True;
         end if;

         X1 := @ + (X2 - X1) / (Y2 - Y1) * (Ymin - Y1);
         Y1 := Ymin;

      elsif Y1 > Ymax then
         if Y2 >= Ymax then
            return True;
         end if;

         X1 := @ + (X2 - X1) / (Y2 - Y1) * (Ymax - Y1);
         Y1 := Ymax;
      end if;

      if Y2 < Ymin then
         X2 := @ + (X2 - X1) / (Y2 - Y1) * (Ymin - Y2);
         Y2 := Ymin;

      elsif Y2 > Ymax then
         X2 := @ + (X2 - X1) / (Y2 - Y1) * (Ymax - Y2);
         Y2 := Ymax;
      end if;

      return False;
   end Clip_Line;

   ---------------
   -- Draw_Line --
   ---------------

   procedure Draw_Line
     (X1 : GFX.Drawing.Device_Pixel_Coordinate;
      Y1 : GFX.Drawing.Device_Pixel_Coordinate;
      X2 : GFX.Drawing.Device_Pixel_Coordinate;
      Y2 : GFX.Drawing.Device_Pixel_Coordinate)
   is
      use A0B.Types;
      use type A0B.Types.Integer_32;

      function "*" (Left : RGBA8888; Right : A0B.Types.Integer_32) return RGBA8888
        with Pre => Right in 0 .. 255;

      function Blend (V : RGBA8888; C : RGBA8888) return RGBA8888;

      procedure Draw_Pixel
        (X : GFX.Drawing.Device_Pixel_Index;
         Y : GFX.Drawing.Device_Pixel_Index;
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
        (X : GFX.Drawing.Device_Pixel_Index;
         Y : GFX.Drawing.Device_Pixel_Index;
         A : A0B.Types.Integer_32)
      is
         XU : constant GFX.Drawing.Device_Pixel_Index := X;
         YU : constant GFX.Drawing.Device_Pixel_Index := Y;
         C  : constant RGBA8888 := Color * A;

      begin
         if X >= Xd_Min and X <= Xd_Max
           and Y >= Yd_Min and Y <= Yd_Max
         then
            Set_Pixel (XU, YU, Blend (Get_Pixel (XU, YU), C));
         end if;
      end Draw_Pixel;

      Xf1 : GFX.Real := X1;
      Yf1 : GFX.Real := Y1;
      Xf2 : GFX.Real := X2;
      Yf2 : GFX.Real := Y2;

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

      Xi1 : A0B.Types.Integer_32 := A0B.Types.Integer_32 (X1 * 64.0);
      Yi1 : A0B.Types.Integer_32 := A0B.Types.Integer_32 (Y1 * 64.0);
      Xi2 : A0B.Types.Integer_32 := A0B.Types.Integer_32 (X2 * 64.0);
      Yi2 : A0B.Types.Integer_32 := A0B.Types.Integer_32 (Y2 * 64.0);
      --  Map float point coordinates to subpixels.

      DX  : constant A0B.Types.Integer_32 := Xi2 - Xi1;
      DY  : constant A0B.Types.Integer_32 := Yi2 - Yi1;

      A    : A0B.Types.Integer_32;
      AS   : A0B.Types.Integer_32;
      AE   : A0B.Types.Integer_32;

   begin
      if Width /= 1.0 then
         Draw_Thick_Line ((X1, Y1), (X2, Y2));
      end if;

      --  Clip line by device area

      if Clip_Line (Xf1, Yf1, Xf2, Yf2) then
         return;
      end if;

      Xi1 := A0B.Types.Integer_32 (Xf1 * 64.0);
      Yi1 := A0B.Types.Integer_32 (Yf1 * 64.0);
      Xi2 := A0B.Types.Integer_32 (Xf2 * 64.0);
      Yi2 := A0B.Types.Integer_32 (Yf2 * 64.0);
      --  Map float point coordinates to subpixels.

      if abs DX < abs DY then
         declare
            Y    : GFX.Drawing.Device_Pixel_Index;
            YS   : GFX.Drawing.Device_Pixel_Index;
            X    : Fixed_16_16;
            Xinc : Fixed_16_16;

         begin
            Xinc := To_Fixed_16_16_Div (DX, DY);

            if Yi1 > Yi2 then
               declare
                  Aux : A0B.Types.Integer_32;

               begin
                  Aux := Xi1;
                  Xi1 := Xi2;
                  Xi2 := Aux;

                  Aux := Yi1;
                  Yi1 := Yi2;
                  Yi2 := Aux;
               end;
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

            Y  :=
              GFX.Drawing.Device_Pixel_Index (Shift_Right_Arithmetic (Yi1, 6));
            YS :=
              GFX.Drawing.Device_Pixel_Index (Shift_Right_Arithmetic (Yi2, 6));

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
              (Integral (X),
               Y,
               Shift_Right_Arithmetic ((A xor 16#FF#) * AS, 6));
            Draw_Pixel
              (Integral (X) + 1,
               Y,
               Shift_Right_Arithmetic (A * AS, 6));

            X := @ + Xinc;
            Y := @ + 1;

            while Y < YS loop
               A := Shift_Right_Arithmetic (X, 8) and 16#FF#;
               Draw_Pixel (Integral (X), Y, A xor 16#FF#);
               Draw_Pixel (Integral (X) + 1, Y, A);

               X := @ + Xinc;
               Y := @ + 1;
            end loop;

            --  Draw the last pixel of the line

            A := Shift_Right_Arithmetic (X, 8) and 16#FF#;
            Draw_Pixel
              (Integral (X),
               Y,
               Shift_Right_Arithmetic ((A xor 16#FF#) * AE, 6));
            Draw_Pixel
              (Integral (X) + 1,
               Y,
               Shift_Right_Arithmetic (A * AE, 6));
         end;

      else
         if DX = 0 then
            return;
         end if;

         declare
            X    : GFX.Drawing.Device_Pixel_Index;
            XS   : GFX.Drawing.Device_Pixel_Index;
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

            X  :=
              GFX.Drawing.Device_Pixel_Index (Shift_Right_Arithmetic (Xi1, 6));
            XS :=
              GFX.Drawing.Device_Pixel_Index (Shift_Right_Arithmetic (Xi2, 6));

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
               Integral (Y),
               Shift_Right_Arithmetic ((A xor 16#FF#) * AS, 6));
            Draw_Pixel
              (X,
               Integral (Y) + 1,
               Shift_Right_Arithmetic (A * AS, 6));

            Y := @ + Yinc;
            X := @ + 1;

            while X < XS loop
               A := Shift_Right_Arithmetic (Y, 8) and 16#FF#;
               Draw_Pixel (X, Integral (Y), A xor 16#FF#);
               Draw_Pixel (X, Integral (Y) + 1, A);

               Y := @ + Yinc;
               X := @ + 1;
            end loop;

            A := Shift_Right_Arithmetic (Y, 8) and 16#FF#;
            Draw_Pixel
              (X,
               Integral (Y),
               Shift_Right_Arithmetic ((A xor 16#FF#) * AE, 6));
            Draw_Pixel
              (X,
               Integral (Y) + 1,
               Shift_Right_Arithmetic (A * AE, 6));
         end;
      end if;
   end Draw_Line;

   ---------------------
   -- Draw_Thick_Line --
   ---------------------

   procedure Draw_Thick_Line
     (A : GFX.Points.GF_Point;
      B : GFX.Points.GF_Point)
   is
      AX : GFX.Real := A.X;
      AY : GFX.Real := A.Y;
      BX : GFX.Real := B.X;
      BY : GFX.Real := B.Y;

   begin
      if Clip_Line (AX, AY, BX, BY) then
         return;
      end if;

      GFX.Drawing.Primitive_Rasterizer.Draw_Line
        ((AX, AY), (BX, BY), Width, Fill_Span'Access);
   end Draw_Thick_Line;

   ---------------
   -- Fill_Span --
   ---------------

   procedure Fill_Span
     (X        : GFX.Drawing.Device_Pixel_Index;
      Y        : GFX.Drawing.Device_Pixel_Index;
      Width    : GFX.Drawing.Device_Pixel_Count;
      Coverage : GFX.Drawing.Grayscale)
   is
      use Interfaces;
      --  use type A0B.Types.Unsigned_32;

      procedure Draw_Pixel
        (X : GFX.Drawing.Device_Pixel_Index;
         Y : GFX.Drawing.Device_Pixel_Index;
         A : A0B.Types.Integer_32);

      function "*"
        (Left : RGBA8888; Right : A0B.Types.Integer_32) return RGBA8888
        with Pre => Right in 0 .. 255;

      function Blend (V : RGBA8888; C : RGBA8888) return RGBA8888;

      ---------
      -- "*" --
      ---------

      function "*"
        (Left : RGBA8888; Right : A0B.Types.Integer_32) return RGBA8888
      is
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
         --  use type A0B.Types.Unsigned_32;

      begin
         return
           C + V * A0B.Types.Integer_32
             (A0B.Types.Shift_Right (not A0B.Types.Unsigned_32 (C), 24));
      end Blend;

      ----------------
      -- Draw_Pixel --
      ----------------

      procedure Draw_Pixel
        (X : GFX.Drawing.Device_Pixel_Index;
         Y : GFX.Drawing.Device_Pixel_Index;
         A : A0B.Types.Integer_32)
      is
         XU : constant GFX.Drawing.Device_Pixel_Index := X;
         YU : constant GFX.Drawing.Device_Pixel_Index := Y;
         C  : constant RGBA8888 := Color * A;

      begin
         if X >= Xd_Min and X <= Xd_Max
           and Y >= Yd_Min and Y <= Yd_Max
         then
            Set_Pixel (XU, YU, Blend (Get_Pixel (XU, YU), C));
         end if;
      end Draw_Pixel;

   begin
      for Current_X in X .. X + Width - 1 loop
         Draw_Pixel (Current_X, Y, A0B.Types.Integer_32 (Coverage));
      end loop;
   end Fill_Span;

   --------------
   -- Integral --
   --------------

   function Integral
     (Item : Fixed_16_16) return GFX.Drawing.Device_Pixel_Index is
   begin
      return GFX.Drawing.Device_Pixel_Index (Shift_Right_Arithmetic (Item, 16));
   end Integral;

   --------------
   -- Set_Clip --
   --------------

   procedure Set_Clip
     (Top    : GFX.Drawing.Device_Pixel_Coordinate;
      Left   : GFX.Drawing.Device_Pixel_Coordinate;
      Right  : GFX.Drawing.Device_Pixel_Coordinate;
      Bottom : GFX.Drawing.Device_Pixel_Coordinate) is
   begin
      Xmin := GFX.Real'Max (0.0, Left + 0.5) - 1.0;
      Xmax := GFX.Real'Min (GFX.Real (Device_Width), Right + 0.5);
      Ymin := GFX.Real'Max (0.0, Top + 0.5) - 1.0;
      Ymax := GFX.Real'Min (GFX.Real (Device_Height), Bottom + 0.5);

      Xd_Min :=
        GFX.Drawing.Device_Pixel_Index'Max
          (0, GFX.Drawing.Device_Pixel_Index (Left + 0.5));
      Xd_Max :=
        GFX.Drawing.Device_Pixel_Index'Min
          (Device_Width - 1, GFX.Drawing.Device_Pixel_Index (Right - 0.5));
      Yd_Min :=
        GFX.Drawing.Device_Pixel_Index'Max
          (0, GFX.Drawing.Device_Pixel_Index (Top + 0.5));
      Yd_Max :=
        GFX.Drawing.Device_Pixel_Index'Min
          (Device_Height - 1, GFX.Drawing.Device_Pixel_Index (Bottom - 0.5));
   end Set_Clip;

   ------------------
   -- Set_Settings --
   ------------------

   procedure Set_Settings
     (Color : GFX.RGBA8888;
      Width : GFX.Real) is
   begin
      Rasterizer.Color := Color;
      Rasterizer.Width := Width;
   end Set_Settings;

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
