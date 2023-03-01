#export PATH := ../../go-nes/bin:/c/Program Files/Aseprite:../../tools/cc65/bin:$(PATH)
.PHONY: all clean

NAME = platforming

NESCFG = nes_000.cfg
CAFLAGS = -g -t nes
LDFLAGS = -C $(NESCFG) --dbgfile bin/$(NAME).dbg -m bin/$(NAME).map
CHRUTIL = go-nes/bin/chrutil

SOURCES = main.asm \
		  map-data.asm \
		  tiles.chr

all: $(CHRUTIL) bin/ bin/$(NAME).nes

bin/:
	mkdir -p bin

bin/$(NAME).o: $(SOURCES)
	ca65 $(CAFLAGS) -o $@ $<

bin/$(NAME).nes: bin/$(NAME).o
	ld65 $(LDFLAGS) -o $@ $^

clean:
	-rm bin/* *.chr

cleanall: clean
	-rm *.bmp go-nes/bin/*

tiles.chr: tiles.bmp
	$(CHRUTIL) -o $@ $<

tiles.bmp: tiles.aseprite
	aseprite -b $< --save-as $@

$(CHRUTIL):
	$(MAKE) -C go-nes bin/chrutil
