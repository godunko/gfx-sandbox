--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Implementaion for STM32F407 microcontroller run @168 MHz.
--
--  It uses SPI1 controller and DMA2 streams 0/3 (RX/TX).

pragma Ada_2022;

with System.Storage_Elements;

with A0B.ARMv7M.NVIC_Utilities; use A0B.ARMv7M.NVIC_Utilities;
with A0B.STM32F407.GPIO;
with A0B.STM32F407.SVD.DMA;     use A0B.STM32F407.SVD.DMA;
with A0B.STM32F407.SVD.RCC;     use A0B.STM32F407.SVD.RCC;
with A0B.STM32F407.SVD.SPI;     use A0B.STM32F407.SVD.SPI;

separate (GFX.ILI9488)
package body SPI is

   --  MISO  : A0B.STM32F407.GPIO.GPIO_Line renames A0B.STM32F407.GPIO.PA6;
   --  MOSI  : A0B.STM32F407.GPIO.GPIO_Line renames A0B.STM32F407.GPIO.PA7;
   --  SCK   : A0B.STM32F407.GPIO.GPIO_Line renames A0B.STM32F407.GPIO.PA5;
   --  NSS   : A0B.STM32F407.GPIO.GPIO_Line renames A0B.STM32F407.GPIO.PA4;
   --  DC    : A0B.STM32F407.GPIO.GPIO_Line renames A0B.STM32F407.GPIO.PA2;
   --  RESET : A0B.STM32F407.GPIO.GPIO_Line renames A0B.STM32F407.GPIO.PA1;
   --  LED   : A0B.STM32F407.GPIO.GPIO_Line renames A0B.STM32F407.GPIO.PA3;

   procedure Transmit (Byte : A0B.Types.Unsigned_8);

   Asynchronous_Busy : Boolean := False with Volatile;
   Transmit_Buffer   : access Unsigned_8_Array;
   Transmit_Index    : A0B.Types.Unsigned_32;
   Transmit_Count    : A0B.Types.Unsigned_32;
   Finished_Callback : A0B.Callbacks.Callback;
   Receive_Buffer    : aliased A0B.Types.Unsigned_8 with Volatile;

   procedure SPI1_Handler
     with Export, Convention => C, External_Name => "SPI1_Handler";

   procedure DMA2_Stream0_Handler
     with Export, Convention => C, External_Name => "DMA2_Stream0_Handler";

   procedure DMA2_Stream3_Handler
     with Export, Convention => C, External_Name => "DMA2_Stream3_Handler";

   --------------------------
   -- DMA2_Stream0_Handler --
   --------------------------

   procedure DMA2_Stream0_Handler is
   begin
      --  Clear interrupt status (both stream 0 (RX) and stream 3 (TX))

      DMA2_Periph.LIFCR :=
        (CFEIF0  => True,
         CDMEIF0 => True,
         CTEIF0  => True,
         CHTIF0  => True,
         CTCIF0  => True,
         CFEIF3  => True,
         CDMEIF3 => True,
         CTEIF3  => True,
         CHTIF3  => True,
         CTCIF3  => True,
         others  => <>);

      --  Disable use of DMA by SPI

      SPI1_Periph.CR2.RXDMAEN := False;
      SPI1_Periph.CR2.TXDMAEN := False;

      --  Wait till BSY flag is set to False and disable SPI controller.

      while SPI1_Periph.SR.BSY loop
         null;
      end loop;

      SPI1_Periph.CR1.SPE := False;

      --  Mark that asynchronous operation has been done.

      Asynchronous_Busy := False;

      A0B.Callbacks.Emit (Finished_Callback);
   end DMA2_Stream0_Handler;

   --------------------------
   -- DMA2_Stream3_Handler --
   --------------------------

   procedure DMA2_Stream3_Handler is
   begin
      --  This interrupt is not used.

      raise Program_Error;
   end DMA2_Stream3_Handler;

   -------------
   -- Disable --
   -------------

   procedure Disable is
   begin
      while SPI1_Periph.SR.BSY loop
         null;
      end loop;

      SPI1_Periph.CR1.SPE := False;
   end Disable;

   ------------
   -- Enable --
   ------------

   procedure Enable is
   begin
      SPI1_Periph.CR1.SPE := True;
   end Enable;

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

      Clear_Pending (A0B.STM32F407.SPI1);
      Enable_Interrupt (A0B.STM32F407.SPI1);

      --  Configure DMA2

      RCC_Periph.AHB1ENR.DMA2EN := True;

      --  Stream 0 (SPI1_RX)
      --
      --  Received data is not used anywhere, so single byte buffer is used
      --  without memory increment.

      DMA2_Periph.S0CR :=
        (EN      => False,  --  0: Stream disabled
         DMEIE   => False,  --  0: DME interrupt disabled
         TEIE    => False,  --  0: TE interrupt disabled
         HTIE    => False,  --  0: HT interrupt disabled
         TCIE    => True,   --  1: TC interrupt enabled
         PFCTRL  => False,  --  0: The DMA is the flow controller
         DIR     => 2#00#,  --  00: Peripheral-to-memory
         CIRC    => False,  --  0: Circular mode disabled
         PINC    => False,  --  0: Peripheral address pointer is fixed
         MINC    => False,  --  0: Memory address pointer is fixed
         --  MINC    => True,
         --  1: Memory address pointer is incremented after each data transfer
         --  (increment is done according to MSIZE)
         PSIZE  => 2#00#,   --  00: Byte (8-bit)
         MSIZE  => 2#00#,   --  00: byte (8-bit)
         PINCOS => <>,      --  This bit has no meaning if bit PINC = '0'.
         PL     => 2#01#,   --  01: Medium
         DBM    => False,   --  0: No buffer switching at the end of transfer
         CT     => <>,      --  only in double buffer mode
         PBURST => 2#00#,   --  00: single transfer
         MBURST => 2#00#,   --  00: single transfer
         CHSEL  => 2#011#,  --  011: channel 3 selected
         others => <>);

      DMA2_Periph.S0PAR :=
        A0B.Types.Unsigned_32
          (System.Storage_Elements.To_Integer (SPI1_Periph.DR'Address));
      DMA2_Periph.S0M0AR :=
        A0B.Types.Unsigned_32
          (System.Storage_Elements.To_Integer (Receive_Buffer'Address));

      Clear_Pending (A0B.STM32F407.DMA2_Stream0);
      Enable_Interrupt (A0B.STM32F407.DMA2_Stream0);

      --  Stream 3 (SPI1_TX)

      DMA2_Periph.S3CR :=
        (EN      => False,  --  0: Stream disabled
         DMEIE   => False,  --  0: DME interrupt disabled
         TEIE    => False,  --  0: TE interrupt disabled
         HTIE    => False,  --  0: HT interrupt disabled
         TCIE    => False,  --  0: TC interrupt disabled
         PFCTRL  => False,  --  0: The DMA is the flow controller
         DIR     => 2#01#,  --  01: Memory-to-peripheral
         CIRC    => False,  --  0: Circular mode disabled
         PINC    => False,  --  0: Peripheral address pointer is fixed
         MINC    => True,
         --  1: Memory address pointer is incremented after each data transfer
         --  (increment is done according to MSIZE)
         PSIZE  => 2#00#,   --  00: Byte (8-bit)
         MSIZE  => 2#00#,   --  00: byte (8-bit)
         PINCOS => <>,      --  This bit has no meaning if bit PINC = '0'.
         PL     => 2#01#,   --  01: Medium
         DBM    => False,   --  0: No buffer switching at the end of transfer
         CT     => <>,      --  only in double buffer mode
         PBURST => 2#00#,   --  00: single transfer
         MBURST => 2#00#,   --  00: single transfer
         CHSEL  => 2#011#,  --  011: channel 3 selected
         others => <>);

      DMA2_Periph.S3PAR :=
        A0B.Types.Unsigned_32
          (System.Storage_Elements.To_Integer (SPI1_Periph.DR'Address));

      Clear_Pending (A0B.STM32F407.DMA2_Stream3);
      Enable_Interrupt (A0B.STM32F407.DMA2_Stream3);
   end Initialize;

   --------------------
   -- Initiate_Write --
   --------------------

   procedure Initiate_Write
     (Packet   : Command_Data_Packet;
      Callback : A0B.Callbacks.Callback) is
   begin
      if Asynchronous_Busy then
         raise Program_Error;
      end if;

      Asynchronous_Busy := True;
      Transmit_Buffer   := Packet.Data;
      Transmit_Count    := Packet.Size;
      Transmit_Index    := 0;
      Finished_Callback := Callback;

      SPI1_Periph.CR1.SPE := True;

      --  Start transmission of the command byte.

      DC.Set (False);
      SPI1_Periph.CR2.RXNEIE := True;
      SPI1_Periph.DR.DR      := A0B.Types.Unsigned_16 (Packet.Command);
   end Initiate_Write;

   ------------------
   -- Receive_Data --
   ------------------

   procedure Receive_Data (Byte : out A0B.Types.Unsigned_8) is
   begin
      SPI1_Periph.DR.DR := 0;

      while not SPI1_Periph.SR.RXNE loop
         null;
      end loop;

      Byte := A0B.Types.Unsigned_8 (SPI1_Periph.DR.DR);

      while not SPI1_Periph.SR.TXE loop
         null;
      end loop;
   end Receive_Data;

   ------------------
   -- SPI1_Handler --
   ------------------

   procedure SPI1_Handler is
      use type A0B.Types.Unsigned_32;

      Status : constant SR_Register  := SPI1_Periph.SR;
      Mask   : constant CR2_Register := SPI1_Periph.CR2;
      Aux    : A0B.Types.Unsigned_16 with Unreferenced;

   begin
      if Mask.TXEIE and Status.TXE then
         SPI1_Periph.DR.DR :=
           A0B.Types.Unsigned_16 (Transmit_Buffer (Transmit_Index));
         Transmit_Index    := @ + 1;

         if Transmit_Index >= Transmit_Count then
            --  Disable TXE interrupt, there is no more data to transmit.
            --  Transfer will be done when corresponding byte has been
            --  received.

            SPI1_Periph.CR2.TXEIE := False;
         end if;
      end if;

      if Mask.RXNEIE and Status.RXNE then
         --  Data has been received, read received byte.

         Aux := SPI1_Periph.DR.DR;

         SPI1_Periph.CR2.RXNEIE := False;

         --  Configure and enable DMA streams 0/3

         DMA2_Periph.S0NDTR.NDT := S0NDTR_NDT_Field (Transmit_Count);
         DMA2_Periph.S3NDTR.NDT := S0NDTR_NDT_Field (Transmit_Count);
         DMA2_Periph.S3M0AR :=
           A0B.Types.Unsigned_32
             (System.Storage_Elements.To_Integer
                (Transmit_Buffer (Transmit_Buffer'First)'Address));

         DMA2_Periph.S0CR.EN := True;
         DMA2_Periph.S3CR.EN := True;

         --  Wait till BSY flag set to False and set D/C signal to data mode.

         while SPI1_Periph.SR.BSY loop
            null;
         end loop;

         DC.Set (True);

         --  Start DMA transfer

         SPI1_Periph.CR2.RXDMAEN := True;
         SPI1_Periph.CR2.TXDMAEN := True;
      end if;
   end SPI1_Handler;

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

   -------------------
   -- Transmit_Data --
   -------------------

   procedure Transmit_Data (Byte : A0B.Types.Unsigned_8) is
   begin
      Transmit (Byte);
   end Transmit_Data;

   ----------------------
   -- Transmit_Command --
   ----------------------

   procedure Transmit_Command (Command : ILI9488_Command) is
   begin
      DC.Set (False);
      Transmit (A0B.Types.Unsigned_8 (Command));

      while SPI1_Periph.SR.BSY loop
         null;
      end loop;

      DC.Set (True);
   end Transmit_Command;

   -------------------
   -- Wait_Non_Busy --
   -------------------

   procedure Wait_Non_Busy is
   begin
      while SPI1_Periph.SR.BSY loop
         null;
      end loop;
   end Wait_Non_Busy;

end SPI;
