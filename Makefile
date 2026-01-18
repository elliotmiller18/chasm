CC ?= cc
CFLAGS ?= -std=c11 -Wall -Wextra -Wpedantic
LDFLAGS ?=

SDL_CFLAGS := $(shell pkg-config --cflags sdl2)
SDL_LIBS := $(shell pkg-config --libs sdl2)

SDL_IMAGE_PKG := $(shell pkg-config --exists sdl2_image && echo sdl2_image)
ifeq ($(SDL_IMAGE_PKG),)
SDL_IMAGE_PKG := $(shell pkg-config --exists SDL2_image && echo SDL2_image)
endif
SDL_IMAGE_CFLAGS := $(shell pkg-config --cflags $(SDL_IMAGE_PKG))
SDL_IMAGE_LIBS := $(shell pkg-config --libs $(SDL_IMAGE_PKG))

TARGET := chasm
ASM_SOURCES := board.asm
ASM_OBJECTS := $(ASM_SOURCES:.asm=.o)

all: $(TARGET)

$(TARGET): driver.c $(ASM_OBJECTS)
	$(CC) $(CFLAGS) $(SDL_CFLAGS) $(SDL_IMAGE_CFLAGS) -o $@ driver.c $(ASM_OBJECTS) $(SDL_LIBS) $(SDL_IMAGE_LIBS) $(LDFLAGS)

%.o: %.asm
	$(CC) -c -x assembler-with-cpp $< -o $@

clean:
	rm -f $(TARGET) $(ASM_OBJECTS)

.PHONY: all clean
