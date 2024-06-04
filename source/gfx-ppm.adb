--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Ada.Strings.Fixed;
with Ada.Text_IO;

package body GFX.PPM is

   type Raster is
     array (A0B.Types.Unsigned_32 range <>, A0B.Types.Unsigned_32 range <>)
       of A0B.Types.Unsigned_32;

   type Raster_Access is access all Raster;

   Buffer : Raster_Access;

   type RGBA is record
      R : A0B.Types.Unsigned_8;
      G : A0B.Types.Unsigned_8;
      B : A0B.Types.Unsigned_8;
      A : A0B.Types.Unsigned_8;
   end record with Size => 32;

   ----------
   -- Save --
   ----------

   procedure Save (File_Name : String) is
      File : Ada.Text_IO.File_Type;

      W : constant String :=
        Ada.Strings.Fixed.Trim
          (A0B.Types.Unsigned_32'Image (Buffer'Length (1)), Ada.Strings.Both);
      H : constant String :=
        Ada.Strings.Fixed.Trim
          (A0B.Types.Unsigned_32'Image (Buffer'Length (2)), Ada.Strings.Both);

   begin
      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, File_Name);

      Ada.Text_IO.Put_Line (File, "P3");
      Ada.Text_IO.Put_Line (File, W & ' ' & H);
      Ada.Text_IO.Put_Line (File, "255");

      for Row in Buffer'Range (2) loop
         for Column in Buffer'Range (1) loop
            declare
               V : constant RGBA
                 with Import, Address => Buffer (Column, Row)'Address;

               R : constant String :=
                 Ada.Strings.Fixed.Trim
                   (A0B.Types.Unsigned_8'Image (V.R),
                    Ada.Strings.Both);
               G : constant String :=
                 Ada.Strings.Fixed.Trim
                   (A0B.Types.Unsigned_8'Image (V.G),
                    Ada.Strings.Both);
               B : constant String :=
                 Ada.Strings.Fixed.Trim
                   (A0B.Types.Unsigned_8'Image (V.B),
                    Ada.Strings.Both);

            begin
               Ada.Text_IO.Put_Line (File, R & ' ' & G & ' ' & B);
            end;
         end loop;
      end loop;

      Ada.Text_IO.Close (File);
   end Save;

   ---------------
   -- Set_Pixel --
   ---------------

   procedure Set_Pixel
     (X     : A0B.Types.Unsigned_32;
      Y     : A0B.Types.Unsigned_32;
      Color : A0B.Types.Unsigned_32) is
   begin
      Buffer (X, Y) := Color;
   end Set_Pixel;

   --------------
   -- Set_Size --
   --------------

   procedure Set_Size
     (Width : A0B.Types.Unsigned_32; Height : A0B.Types.Unsigned_32)
   is
      use type A0B.Types.Unsigned_32;

   begin
      Buffer := new Raster (0 .. Width - 1, 0 .. Height - 1);
   end Set_Size;

end GFX.PPM;
