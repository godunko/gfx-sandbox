
all: build
	./bin/gfx-driver
	viewnior out.ppm

gimp: build
	./bin/gfx-driver
	gimp out.ppm

check: build-testsuite
	./testsuite/bin/test1
	diff -u testsuite/test1.ppm out.ppm

build-testsuite:
	cd testsuite && alr build

build:
	alr build -- -cargs -O0

clean:
	rm -rf .objs bin config alire

gdb: build
	gdb --command=gdbinit ./bin/gfx-driver

asm:
	alr build -- -c -u -f gfx-painter.adb -cargs -S -O2
	alr build -- -c -u -f gfx-painter.adb --target=arm-eabi --RTS=light-cortex-m7f -cargs -S -O2
