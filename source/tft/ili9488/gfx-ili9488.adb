--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  pragma Ada_2022;

with A0B.Delays;
with A0B.STM32F407.GPIO;
with A0B.Time;

package body GFX.ILI9488 is

   procedure PendSV_Handler is null
     with Export, Convention => C, External_Name => "PendSV_Handler";

   MISO  : A0B.STM32F407.GPIO.GPIO_Line renames A0B.STM32F407.GPIO.PA6;
   MOSI  : A0B.STM32F407.GPIO.GPIO_Line renames A0B.STM32F407.GPIO.PA7;
   SCK   : A0B.STM32F407.GPIO.GPIO_Line renames A0B.STM32F407.GPIO.PA5;
   NSS   : A0B.STM32F407.GPIO.GPIO_Line renames A0B.STM32F407.GPIO.PA4;
   DC    : A0B.STM32F407.GPIO.GPIO_Line renames A0B.STM32F407.GPIO.PA2;
   RESET : A0B.STM32F407.GPIO.GPIO_Line renames A0B.STM32F407.GPIO.PA1;
   LED   : A0B.STM32F407.GPIO.GPIO_Line renames A0B.STM32F407.GPIO.PA3;

   type ILI9488_Command is new A0B.Types.Unsigned_8;

   SLPOUT : constant ILI9488_Command := 16#11#;
   DISON  : constant ILI9488_Command := 16#29#;
   CASET  : constant ILI9488_Command := 16#2A#;
   PASET  : constant ILI9488_Command := 16#2B#;
   RAMWR  : constant ILI9488_Command := 16#2C#;
   RAMRD  : constant ILI9488_Command := 16#2E#;
   MADCTL : constant ILI9488_Command := 16#36#;
   COLMOD : constant ILI9488_Command := 16#3A#;

   procedure Command (Command : ILI9488_Command);

   procedure Set_COLMOD;

   procedure Set_MADCTL;

   procedure Set_CAPA
     (SX : A0B.Types.Unsigned_16;
      EX : A0B.Types.Unsigned_16;
      SY : A0B.Types.Unsigned_16;
      EY : A0B.Types.Unsigned_16);

   procedure Fill;

   package SPI is

      procedure Initialize;

      procedure Enable;

      procedure Disable;

      procedure Transmit_Data (Byte : A0B.Types.Unsigned_8);

      procedure Receive_Data (Byte : out A0B.Types.Unsigned_8);

      procedure Transmit_Command (Command : ILI9488_Command);

      procedure Wait_Non_Busy;

   end SPI;

   -------------
   -- Command --
   -------------

   procedure Command (Command : ILI9488_Command) is
   begin
      SPI.Enable;
      SPI.Transmit_Command (Command);
      SPI.Disable;
   end Command;

   ------------
   -- Enable --
   ------------

   procedure Enable is
   begin
      RESET.Set (False);
      A0B.Delays.Delay_For (A0B.Time.Microseconds (10));
      RESET.Set (True);
      A0B.Delays.Delay_For (A0B.Time.Milliseconds (120));

      Command (SLPOUT);
      A0B.Delays.Delay_For (A0B.Time.Milliseconds (120));

      Command (DISON);
      A0B.Delays.Delay_For (A0B.Time.Milliseconds (120));

      LED.Set (True);

      Set_COLMOD;
      Set_MADCTL;
      A0B.Delays.Delay_For (A0B.Time.Milliseconds (1));
      --  It is unclear why this delay is necessary.

      Set_CAPA (0, 479, 0, 319);

      Fill;
   end Enable;

   ----------
   -- Fill --
   ----------

   procedure Fill is
   begin
      SPI.Enable;
      SPI.Transmit_Command (RAMWR);

      for J in 0 .. (320 * 480 * 1) - 1 loop
         SPI.Transmit_Data (16#00#);
         SPI.Transmit_Data (16#00#);
         SPI.Transmit_Data (16#00#);
      end loop;

      SPI.Disable;
   end Fill;

   ---------------
   -- Get_Pixel --
   ---------------

   function Get_Pixel
     (X : A0B.Types.Unsigned_32;
      Y : A0B.Types.Unsigned_32) return GFX.RGBA8888
   is
      R : A0B.Types.Unsigned_8;
      G : A0B.Types.Unsigned_8;
      B : A0B.Types.Unsigned_8;

   begin
      Set_CAPA
        (A0B.Types.Unsigned_16 (X),
         A0B.Types.Unsigned_16 (X),
         A0B.Types.Unsigned_16 (Y),
         A0B.Types.Unsigned_16 (Y));

      --  Enable SPI

      SPI.Enable;

      --  Read GRAM at pixel

      SPI.Transmit_Command (RAMRD);
      SPI.Receive_Data (R);
      SPI.Receive_Data (G);
      SPI.Receive_Data (B);

      --  Disable SPI

      SPI.Disable;

      return GFX.To_RGBA (R, G, B, 16#FF#);
   end Get_Pixel;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      SPI.Initialize;

      RESET.Configure_Output
        (Speed => A0B.STM32F407.GPIO.Very_High,
         Pull  => A0B.STM32F407.GPIO.Pull_Up);
      LED.Configure_Output
        (Speed => A0B.STM32F407.GPIO.Low,
         Pull  => A0B.STM32F407.GPIO.Pull_Up);
   end Initialize;

   --------------
   -- Set_CAPA --
   --------------

   procedure Set_CAPA
     (SX : A0B.Types.Unsigned_16;
      EX : A0B.Types.Unsigned_16;
      SY : A0B.Types.Unsigned_16;
      EY : A0B.Types.Unsigned_16)
   is
      use type A0B.Types.Unsigned_16;

      SXH : constant A0B.Types.Unsigned_8 :=
        A0B.Types.Unsigned_8 (A0B.Types.Shift_Right (SX, 8));
      SXL : constant A0B.Types.Unsigned_8 :=
        A0B.Types.Unsigned_8 (SX and 16#FF#);
      EXH : constant A0B.Types.Unsigned_8 :=
        A0B.Types.Unsigned_8 (A0B.Types.Shift_Right (EX, 8));
      EXL : constant A0B.Types.Unsigned_8 :=
        A0B.Types.Unsigned_8 (EX and 16#FF#);

      SYH : constant A0B.Types.Unsigned_8 :=
        A0B.Types.Unsigned_8 (A0B.Types.Shift_Right (SY, 8));
      SYL : constant A0B.Types.Unsigned_8 :=
        A0B.Types.Unsigned_8 (SY and 16#FF#);
      EYH : constant A0B.Types.Unsigned_8 :=
        A0B.Types.Unsigned_8 (A0B.Types.Shift_Right (EY, 8));
      EYL : constant A0B.Types.Unsigned_8 :=
        A0B.Types.Unsigned_8 (EY and 16#FF#);

   begin
      --  Enable SPI

      SPI.Enable;

      --  Set Column Address (horizontal range)

      SPI.Transmit_Command (CASET);
      SPI.Transmit_Data (SXH);
      SPI.Transmit_Data (SXL);
      SPI.Transmit_Data (EXH);
      SPI.Transmit_Data (EXL);

      SPI.Wait_Non_Busy;

      --  Set Page Address (vertical range)

      SPI.Transmit_Command (PASET);
      SPI.Transmit_Data (SYH);
      SPI.Transmit_Data (SYL);
      SPI.Transmit_Data (EYH);
      SPI.Transmit_Data (EYL);

      --  Disalble SPI

      SPI.Disable;
   end Set_CAPA;

   ----------------
   -- Set_COLMOD --
   ----------------

   procedure Set_COLMOD is
      Aux : A0B.Types.Unsigned_16 with Unreferenced;

   begin
      SPI.Enable;
      SPI.Transmit_Command (COLMOD);
      SPI.Transmit_Data (2#0110_0110#);
      SPI.Disable;
   end Set_COLMOD;

   ----------------
   -- Set_MADCTL --
   ----------------

   procedure Set_MADCTL is
   begin
      SPI.Enable;
      SPI.Transmit_Command (MADCTL);
      SPI.Transmit_Data (2#0010_0000#);
      --  D5: Row/Column Exchange
      SPI.Disable;
   end Set_MADCTL;

   ---------
   -- Set --
   ---------

   procedure Set
     (X : GFX.Implementation.Device_Point_Coordinate;
      Y : GFX.Implementation.Device_Point_Coordinate;
      S : not null access GFX.Implementation.Backing_Store.Storage_Array)
   is
      use type GFX.Implementation.Device_Point_Coordinate;

      R : A0B.Types.Unsigned_8;
      G : A0B.Types.Unsigned_8;
      B : A0B.Types.Unsigned_8;
      A : A0B.Types.Unsigned_8;

   begin
      Set_CAPA
        (A0B.Types.Unsigned_16 (X),
         A0B.Types.Unsigned_16 (X + 32 - 1),
         A0B.Types.Unsigned_16 (Y),
         A0B.Types.Unsigned_16 (Y + 32 - 1));

      --  Enable SPI

      SPI.Enable;

      --  Start GRAM write operation

      SPI.Transmit_Command (RAMWR);

      for J in S'Range loop
         GFX.From_RGBA8888 (S (J), R, G, B, A);

         --  Write pixel into GRAM

         SPI.Transmit_Data (R);
         SPI.Transmit_Data (G);
         SPI.Transmit_Data (B);
      end loop;

      --  Disable SPI

      SPI.Disable;
   end Set;

   ---------------
   -- Set_Pixel --
   ---------------

   procedure Set_Pixel
     (X     : A0B.Types.Unsigned_32;
      Y     : A0B.Types.Unsigned_32;
      Color : GFX.RGBA8888)
   is
      R : A0B.Types.Unsigned_8;
      G : A0B.Types.Unsigned_8;
      B : A0B.Types.Unsigned_8;
      A : A0B.Types.Unsigned_8;

   begin
      GFX.From_RGBA8888 (Color, R, G, B, A);

      Set_CAPA
        (A0B.Types.Unsigned_16 (X),
         A0B.Types.Unsigned_16 (X),
         A0B.Types.Unsigned_16 (Y),
         A0B.Types.Unsigned_16 (Y));

      --  Enable SPI

      SPI.Enable;

      --  Write GRAM at pixel

      SPI.Transmit_Command (RAMWR);
      SPI.Transmit_Data (R);
      SPI.Transmit_Data (G);
      SPI.Transmit_Data (B);

      --  Disable SPI

      SPI.Disable;
   end Set_Pixel;

   ---------
   -- SPI --
   ---------

   package body SPI is separate;

end GFX.ILI9488;
