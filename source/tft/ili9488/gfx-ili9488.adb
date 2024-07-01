--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  pragma Ada_2022;

with A0B.Delays;
with A0B.STM32F407.GPIO;
with A0B.STM32F407.SVD.RCC; use A0B.STM32F407.SVD.RCC;
with A0B.STM32F407.SVD.SPI; use A0B.STM32F407.SVD.SPI;
with A0B.Time;

package body GFX.ILI9488 is

   procedure PendSV_Handler is null
     with Export, Convention => C, External_Name => "PendSV_Handler";
   --  type Raster is
   --    array (A0B.Types.Unsigned_32 range <>, A0B.Types.Unsigned_32 range <>)
   --      of GFX.RGBA8888;
   --
   --  type Raster_Access is access all Raster;
   --
   --  Buffer : Raster_Access;
   --
   --  type RGBA is record
   --     R : A0B.Types.Unsigned_8;
   --     G : A0B.Types.Unsigned_8;
   --     B : A0B.Types.Unsigned_8;
   --     A : A0B.Types.Unsigned_8;
   --  end record with Size => 32;

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
   --  RAMRD  : constant ILI9488_Command := 16#2E#;
   --  MADCTL : constant ILI9488_Command := 16#36#;
   COLMOD : constant ILI9488_Command := 16#3A#;

   procedure Command (Command : ILI9488_Command);

   procedure Set_COLMOD;

   procedure Set_CAPA
     (SX : A0B.Types.Unsigned_16;
      EX : A0B.Types.Unsigned_16;
      SY : A0B.Types.Unsigned_16;
      EY : A0B.Types.Unsigned_16);

   procedure Fill;

   procedure Transmit (Byte : A0B.Types.Unsigned_8);

   -------------
   -- Command --
   -------------

   procedure Command (Command : ILI9488_Command) is
      Aux : A0B.Types.Unsigned_16 with Unreferenced;

   begin
      SPI1_Periph.CR1.SPE := True;
      DC.Set (False);

      SPI1_Periph.DR.DR := A0B.Types.Unsigned_16 (Command);

      while not SPI1_Periph.SR.RXNE loop
         null;
      end loop;

      Aux := SPI1_Periph.DR.DR;

      while not SPI1_Periph.SR.TXE loop
         null;
      end loop;

      while SPI1_Periph.SR.BSY loop
         null;
      end loop;

      SPI1_Periph.CR1.SPE := False;
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
      --  for J in 1 .. 84_000_000 loop
      --     null;
      --  end loop;

      Command (DISON);
      A0B.Delays.Delay_For (A0B.Time.Milliseconds (120));

      LED.Set (True);

      Set_COLMOD;
      --  Set_CAPA (0, 479, 0, 319);
      Set_CAPA (0, 319, 0, 479);

      Fill;
   end Enable;

   ----------
   -- Fill --
   ----------

   procedure Fill is
      Aux : A0B.Types.Unsigned_16 with Unreferenced;

   begin
      SPI1_Periph.CR1.SPE := True;
      DC.Set (False);

      SPI1_Periph.DR.DR := A0B.Types.Unsigned_16 (RAMWR);

      while not SPI1_Periph.SR.RXNE loop
         null;
      end loop;

      Aux := SPI1_Periph.DR.DR;

      while not SPI1_Periph.SR.TXE loop
         null;
      end loop;

      DC.Set (True);

      for J in 0 .. (320 * 480 * 1) - 1 loop
         SPI1_Periph.DR.DR := A0B.Types.Unsigned_16 (16#00#);

         while not SPI1_Periph.SR.RXNE loop
            null;
         end loop;

         Aux := SPI1_Periph.DR.DR;

         while not SPI1_Periph.SR.TXE loop
            null;
         end loop;

         SPI1_Periph.DR.DR := A0B.Types.Unsigned_16 (16#FF#);

         while not SPI1_Periph.SR.RXNE loop
            null;
         end loop;

         Aux := SPI1_Periph.DR.DR;

         while not SPI1_Periph.SR.TXE loop
            null;
         end loop;

         SPI1_Periph.DR.DR := A0B.Types.Unsigned_16 (16#FF#);

         while not SPI1_Periph.SR.RXNE loop
            null;
         end loop;

         Aux := SPI1_Periph.DR.DR;

         while not SPI1_Periph.SR.TXE loop
            null;
         end loop;
      end loop;

      --  Shutdown

      while not SPI1_Periph.SR.TXE loop
         null;
      end loop;

      while SPI1_Periph.SR.BSY loop
         null;
      end loop;

      SPI1_Periph.CR1.SPE := False;
   end Fill;

   ---------------
   -- Get_Pixel --
   ---------------

   function Get_Pixel
     (X : A0B.Types.Unsigned_32;
      Y : A0B.Types.Unsigned_32) return GFX.RGBA8888 is
   begin
      return 0;
   --     return Buffer (X, Y);
   end Get_Pixel;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      RCC_Periph.AHB1ENR.GPIOAEN := True;
      RCC_Periph.APB2ENR.SPI1EN := True;

      SPI1_Periph.CR1.SPE := False;
      --  Disable SPI to be able to configure it.

      SPI1_Periph.CR1 :=
        (CPHA     => False,
         --  The first clock transition is the first data capture edge
         CPOL     => False,   --  CK to 0 when idle
         MSTR     => True,    --  Master configuration
         BR       => 2#001#,  --  fPCLK/4
         --  BR       => 2#011#,  --  fPCLK/16
         SPE      => False,   --  Peripheral disabled
         LSBFIRST => False,   --  MSB transmitted first
         SSI      => False,
         SSM      => False,   --  Software slave management disabled
         RXONLY   => False,   --  Full duplex (Transmit and receive)
         DFF      => False,
         --  8-bit data frame format is selected for transmission/reception
         CRCNEXT  => False,
         CRCEN    => False,   --  CRC calculation disabled
         BIDIOE   => False,
         BIDIMODE => False,   -- 2-line unidirectional data mode selected
         others   => <>);

      SPI1_Periph.CR2 :=
        (RXDMAEN => False,  --  Rx buffer DMA disabled
         TXDMAEN => False,  --  Tx buffer DMA disabled
         SSOE    => True,
         --  SS output is enabled in master mode and when the cell is enabled.
         --  The cell cannot work in a multimaster environment.
         FRF     => False,  --  SPI Motorola mode
         ERRIE   => False,
         RXNEIE  => False,
         TXEIE   => False,
         others  => <>);

      SPI1_Periph.CR1.SPE := True;

      MISO.Configure_Alternative_Function
        (A0B.STM32F407.SPI1_MISO,
         Speed => A0B.STM32F407.GPIO.Very_High,
         Pull  => A0B.STM32F407.GPIO.Pull_Up);
      MOSI.Configure_Alternative_Function
        (A0B.STM32F407.SPI1_MOSI,
         Speed => A0B.STM32F407.GPIO.Very_High,
         Pull  => A0B.STM32F407.GPIO.Pull_Up);
      SCK.Configure_Alternative_Function
        (A0B.STM32F407.SPI1_SCK,
         Speed => A0B.STM32F407.GPIO.Very_High,
         Pull  => A0B.STM32F407.GPIO.Pull_Up);
      NSS.Configure_Alternative_Function
        (A0B.STM32F407.SPI1_NSS,
         Speed => A0B.STM32F407.GPIO.Very_High,
         Pull  => A0B.STM32F407.GPIO.Pull_Up);

      DC.Configure_Output
        (Speed => A0B.STM32F407.GPIO.Very_High,
         Pull  => A0B.STM32F407.GPIO.Pull_Up);
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

      SPI1_Periph.CR1.SPE := True;

      --  Set Column Address (horizontal range)

      DC.Set (False);
      Transmit (A0B.Types.Unsigned_8 (CASET));

      while SPI1_Periph.SR.BSY loop
         null;
      end loop;

      DC.Set (True);
      Transmit (SXH);
      Transmit (SXL);
      Transmit (EXH);
      Transmit (EXL);

      while SPI1_Periph.SR.BSY loop
         null;
      end loop;

      --  Set Page Address (vertical range)

      DC.Set (False);
      Transmit (A0B.Types.Unsigned_8 (PASET));

      while SPI1_Periph.SR.BSY loop
         null;
      end loop;

      DC.Set (True);
      Transmit (SYH);
      Transmit (SYL);
      Transmit (EYH);
      Transmit (EYL);

      while SPI1_Periph.SR.BSY loop
         null;
      end loop;

      --  Disalble SPI

      SPI1_Periph.CR1.SPE := False;
   end Set_CAPA;

   ----------------
   -- Set_COLMOD --
   ----------------

   procedure Set_COLMOD is
      Aux : A0B.Types.Unsigned_16 with Unreferenced;

   begin
      SPI1_Periph.CR1.SPE := True;
      DC.Set (False);

      SPI1_Periph.DR.DR := A0B.Types.Unsigned_16 (COLMOD);

      while not SPI1_Periph.SR.RXNE loop
         null;
      end loop;

      Aux := SPI1_Periph.DR.DR;

      while not SPI1_Periph.SR.TXE loop
         null;
      end loop;

      DC.Set (True);

      --  for J in 0 .. 320*480 - 1 loop
      SPI1_Periph.DR.DR := A0B.Types.Unsigned_16 (2#0110_0110#);

      while not SPI1_Periph.SR.RXNE loop
         null;
      end loop;

      Aux := SPI1_Periph.DR.DR;

      --     while not SPI1_Periph.SR.TXE loop
      --        null;
      --     end loop;
      --
      --  end loop;

      --  Shutdown

      while not SPI1_Periph.SR.TXE loop
         null;
      end loop;

      while SPI1_Periph.SR.BSY loop
         null;
      end loop;

      SPI1_Periph.CR1.SPE := False;
   end Set_COLMOD;

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

      SPI1_Periph.CR1.SPE := True;

      --  Set Column Address (horizontal range)

      DC.Set (False);
      Transmit (A0B.Types.Unsigned_8 (RAMWR));

      while SPI1_Periph.SR.BSY loop
         null;
      end loop;

      DC.Set (True);
      Transmit (R);
      Transmit (G);
      Transmit (B);

      while SPI1_Periph.SR.BSY loop
         null;
      end loop;

      SPI1_Periph.CR1.SPE := False;
   end Set_Pixel;

   --------------
   -- Transmit --
   --------------

   procedure Transmit (Byte : A0B.Types.Unsigned_8) is
      Aux : A0B.Types.Unsigned_16 with Unreferenced;

   begin
      SPI1_Periph.DR.DR := A0B.Types.Unsigned_16 (Byte);

      while not SPI1_Periph.SR.RXNE loop
         null;
      end loop;

      Aux := SPI1_Periph.DR.DR;

      while not SPI1_Periph.SR.TXE loop
         null;
      end loop;
   end Transmit;

end GFX.ILI9488;
