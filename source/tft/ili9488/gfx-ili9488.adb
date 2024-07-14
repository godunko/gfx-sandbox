--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  pragma Ada_2022;

with A0B.Callbacks.Generic_Parameterless;
with A0B.Delays;
with A0B.STM32F407.GPIO;
with A0B.Time;
with A0B.Types;

package body GFX.ILI9488 is

   --  3.5" display, 48.96x73.44 active area, 320x480 resolution

   MM_Inch               : constant := 1.0 / 25.4;
   --  MM to Inch conversion factor

   Horizontal_Size       : constant := 73.44 * MM_Inch;
   Vertical_Size         : constant := 48.96 * MM_Inch;
   Horizontal_Resolution : constant := 480;
   Vertical_Resolution   : constant := 320;
   --  Phisical size (in inches) and resolution of the display.

   CSS_Pixel_Density     : constant := 96.0;
   --  Density of the CSS pixel.

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

   type Unsigned_8_Array is
     array (A0B.Types.Unsigned_32 range <>) of A0B.Types.Unsigned_8;

   type Command_Data_Packet is record
      Command : ILI9488_Command;
      Data    : not null access Unsigned_8_Array;
      Size    : A0B.Types.Unsigned_32;
   end record;

   package SPI is

      procedure Initialize;

      procedure Enable;

      procedure Disable;

      procedure Transmit_Data (Byte : A0B.Types.Unsigned_8);

      procedure Receive_Data (Byte : out A0B.Types.Unsigned_8);

      procedure Transmit_Command (Command : ILI9488_Command);

      procedure Wait_Non_Busy;

      procedure Initiate_Write
        (Packet   : Command_Data_Packet;
         Callback : A0B.Callbacks.Callback);

   end SPI;

   CASET_Data   : aliased Unsigned_8_Array := (0 .. 3 => 0);
   CASET_Packet : constant Command_Data_Packet :=
     (Command => CASET, Data => CASET_Data'Access, Size => 4);
   PASET_Data   : aliased Unsigned_8_Array := (0 .. 3 => 0);
   PASET_Packet : constant Command_Data_Packet :=
     (Command => PASET, Data => PASET_Data'Access, Size => 4);
   RAMWR_Data   : aliased Unsigned_8_Array := (0 .. 12_287 => 0);
   RAMWR_Packet : Command_Data_Packet :=
     (Command => RAMWR, Data => RAMWR_Data'Access, Size => 0);

   Set_Done : Boolean := True with Volatile;

   procedure On_CASET_Finished;

   package On_CASET_Finished_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_CASET_Finished);

   procedure On_PASET_Finished;

   package On_PASET_Finished_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_PASET_Finished);

   procedure On_RAMWR_Finished;

   package On_RAMWR_Finished_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_RAMWR_Finished);

   -------------
   -- Command --
   -------------

   procedure Command (Command : ILI9488_Command) is
   begin
      SPI.Enable;
      SPI.Transmit_Command (Command);
      SPI.Disable;
   end Command;

   -------------------------------
   -- CSS_Device_Transformation --
   -------------------------------

   procedure CSS_Device_Transformation
     (Transformation : out GFX.Transformers.GX_Transformer)
   is
      DH : constant GFX.Real :=
        GFX.Real (Horizontal_Resolution) / Horizontal_Size;
      DV : constant GFX.Real := GFX.Real (Vertical_Resolution) / Vertical_Size;

      SH : constant GFX.Real := DH / CSS_Pixel_Density;
      SV : constant GFX.Real := DV / CSS_Pixel_Density;

   begin
      Transformation.Set_Identity;
      Transformation.Scale (SH, SV);
   end CSS_Device_Transformation;

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
     (X : GFX.Drawing.Device_Pixel_Index;
      Y : GFX.Drawing.Device_Pixel_Index) return GFX.RGBA8888
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

   -----------------------
   -- On_CASET_Finished --
   -----------------------

   procedure On_CASET_Finished is
   begin
      SPI.Initiate_Write
        (PASET_Packet, On_PASET_Finished_Callbacks.Create_Callback);
   end On_CASET_Finished;

   -----------------------
   -- On_PASET_Finished --
   -----------------------

   procedure On_PASET_Finished is
   begin
      SPI.Initiate_Write
        (RAMWR_Packet, On_RAMWR_Finished_Callbacks.Create_Callback);
   end On_PASET_Finished;

   -----------------------
   -- On_RAMWR_Finished --
   -----------------------

   procedure On_RAMWR_Finished is
   begin
      Set_Done := True;
   end On_RAMWR_Finished;

   ------------------
   -- Prepare_CAPA --
   ------------------

   procedure Prepare_CAPA
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
      CASET_Data (0) := SXH;
      CASET_Data (1) := SXL;
      CASET_Data (2) := EXH;
      CASET_Data (3) := EXL;

      PASET_Data (0) := SYH;
      PASET_Data (1) := SYL;
      PASET_Data (2) := EYH;
      PASET_Data (3) := EYL;
   end Prepare_CAPA;

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
     (X : GFX.Drawing.Device_Pixel_Index;
      Y : GFX.Drawing.Device_Pixel_Index;
      W : GFX.Drawing.Device_Pixel_Count;
      H : GFX.Drawing.Device_Pixel_Count;
      S : not null access GFX.Implementation.Backing_Store.Storage_Array)
   is
      R : A0B.Types.Unsigned_8;
      G : A0B.Types.Unsigned_8;
      B : A0B.Types.Unsigned_8;
      A : A0B.Types.Unsigned_8;

   begin
      while not Set_Done loop
         null;
      end loop;

      Prepare_CAPA
        (A0B.Types.Unsigned_16 (X),
         A0B.Types.Unsigned_16 (X + W - 1),
         A0B.Types.Unsigned_16 (Y),
         A0B.Types.Unsigned_16 (Y + H - 1));

      for J in 0 .. (W * H) - 1 loop
         GFX.From_RGBA8888 (S (J), R, G, B, A);

         RAMWR_Data (A0B.Types.Unsigned_32 (J * 3 + 0)) := R;
         RAMWR_Data (A0B.Types.Unsigned_32 (J * 3 + 1)) := G;
         RAMWR_Data (A0B.Types.Unsigned_32 (J * 3 + 2)) := B;
      end loop;

      RAMWR_Packet.Size := A0B.Types.Unsigned_32 (W * H * 3);
      Set_Done := False;

      SPI.Initiate_Write
        (CASET_Packet, On_CASET_Finished_Callbacks.Create_Callback);
   end Set;

   ---------------
   -- Set_Pixel --
   ---------------

   procedure Set_Pixel
     (X     : GFX.Drawing.Device_Pixel_Index;
      Y     : GFX.Drawing.Device_Pixel_Index;
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
