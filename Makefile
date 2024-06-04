
all:
	alr build
	./bin/gfx-driver
	viewnior out.ppm

clean:
	rm -rf .objs bin config alire
