
all: build
	rm -f out.ppm
	./examples/native/bin/demo.elf
	viewnior out.ppm

gimp: build
	rm -f out.ppm
	./examples/native/bin/demo.elf
	gimp out.ppm

check: build-testsuite
	./testsuite/bin/test1
	diff -u testsuite/test1.ppm out.ppm

build-testsuite:
	cd testsuite && alr build

build:
	cd examples/native && alr build -- -cargs -O0

build-stm32f407:
	cd examples/stm32f407_ili9488_gt911 && alr build

clean:
	rm -rf .objs bin config alire

gdb: build
	gdb --command=gdbinit ./bin/gfx-driver

gdb-stm32f407:
	cd examples/stm32f407_ili9488_gt911 && eval `alr printenv` && arm-eabi-gdb bin/demo.elf

asm:
	alr build -- -c -u -f gfx-painter.adb -cargs -S -O2
	alr build -- -c -u -f gfx-painter.adb --target=arm-eabi --RTS=light-cortex-m7f -cargs -S -O2
