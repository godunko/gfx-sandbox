--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with A0B.ARMv7M.NVIC_Utilities; use A0B.ARMv7M.NVIC_Utilities;
with A0B.STM32F407.GPIO;
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
   Finished_Callback : A0B.Callbacks.Callback;

   procedure SPI1_Handler
     with Export, Convention => C, External_Name => "SPI1_Handler";

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

         if Transmit_Index > Transmit_Buffer'Last then
            --  Disable TXE interrupt, there is no more data to transmit.
            --  Transfer will be done when corresponding byte has been
            --  received.

            SPI1_Periph.CR2.TXEIE := False;
         end if;
      end if;

      if Mask.RXNEIE and Status.RXNE then
         --  Data has been received, read received byte.

         Aux := SPI1_Periph.DR.DR;

         --  When data transmission has not beed started, set D/C signal and
         --  enable TX interrupt. Data transmission will be started on next
         --  execution of the interrupt handler.
         --
         --  ??? It should be possible to start data transfer here, why it is
         --  not described in the RM0090?

         if Transmit_Index = Transmit_Buffer'First then
            --  First, wait till BSY flag is recet.

            while SPI1_Periph.SR.BSY loop
               null;
            end loop;

            DC.Set (True);

            --  Enable TXE interrupt.

            SPI1_Periph.CR2.TXEIE := True;
         end if;

         --  Data transmission has been finished, check for receive of the all
         --  data and finish transfer.

         if Transmit_Index > Transmit_Buffer'Last then
            if Status.TXE then
               --  TXE is set when the last byte of the transmitted data has
               --  been transmitted, thus current interrupt read last received
               --  byte.

               --  Disable RXNE interrupt, it is necessary for mixing
               --  synchronous/asynchronous code during transition.

               SPI1_Periph.CR2.RXNEIE := False;

               --  Wait till BSY flag is set to False and disable SPI
               --  controller.

               while SPI1_Periph.SR.BSY loop
                  null;
               end loop;

               SPI1_Periph.CR1.SPE := False;

               --  Mark that asynchronous operation has been done.

               Asynchronous_Busy := False;

               A0B.Callbacks.Emit (Finished_Callback);
            end if;
         end if;
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
