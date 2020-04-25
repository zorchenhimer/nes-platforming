export PATH := ../../tools/cc65/bin:$(PATH)
.PHONY: all clean

NAME = platforming

NESCFG = nes_000.cfg
CAFLAGS = -g -t nes --color-messages
LDFLAGS = -C $(NESCFG) --dbgfile bin/$(NAME).dbg -m bin/$(NAME).map --color-messages

SOURCES = main.asm \
		  map-data.asm

all: bin/ bin/$(NAME).nes

bin/:
	mkdir -p bin

bin/$(NAME).o: $(SOURCES)
	ca65 $(CAFLAGS) -o $@ $<

bin/$(NAME).nes: bin/$(NAME).o
	ld65 $(LDFLAGS) -o $@ $^

clean:
	-rm -rf bin/*
