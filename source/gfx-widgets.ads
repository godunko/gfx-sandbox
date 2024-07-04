--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package GFX.Widgets
  with Preelaborate
is

   type Abstract_Widget is tagged limited private;

   procedure Initialize
     (Self   : out Abstract_Widget'Class;
      Width  : A0B.Types.Integer_32;
      Height : A0B.Types.Integer_32);

   not overriding procedure Paint (Self : in out Abstract_Widget);
   --  ??? Must be private !!!

private

   type Abstract_Widget is tagged limited record
      null;
   end record;

end GFX.Widgets;