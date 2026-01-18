// BEGIN EDITS ALLOWED

#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

// END EDITS ALLOWED

enum {
	BOARD_SIZE = 8,
	SQUARE_SIZE = 32,
	WINDOW_SIZE = BOARD_SIZE * SQUARE_SIZE
};

typedef struct {
	uint8_t squares[BOARD_SIZE * BOARD_SIZE];
} Bitboard;

extern void init_board(Bitboard *board);

const int EMPTY = 0;
const int PAWN = 1;
const int KNIGHT = 2;
const int BISHOP = 3;
const int ROOK = 4;
const int QUEEN = 5;
const int KING = 6;
const int WHITE_TAG = 0b10000000;
const int SELECTED_TAG = 0b01000000;
const int ALLOWED_TAG = 0b00100000;

static void handle_click(Bitboard *board, int mouse_x, int mouse_y) {
	int file = mouse_x / SQUARE_SIZE;
	int rank = mouse_y / SQUARE_SIZE;
	if (file < 0 || file >= BOARD_SIZE || rank < 0 || rank >= BOARD_SIZE) {
		return;
	}

	int idx = (rank * BOARD_SIZE) + file;

	//TODO: arm func (update bitboard for click)
}

// helper function for rendering
static int is_white(uint8_t piece) {
	// the msb is a tag bit
	return piece & WHITE_TAG;
}

// BEGIN EDITS ALLOWED

static void draw_tile(SDL_Renderer *renderer, SDL_Texture *sprites,
		int tile_index, int x, int y) {
	SDL_Rect src = {tile_index * SQUARE_SIZE, 0, SQUARE_SIZE, SQUARE_SIZE};
	SDL_Rect dst = {x, y, SQUARE_SIZE, SQUARE_SIZE};
	SDL_RenderCopy(renderer, sprites, &src, &dst);
}

static void render_board(SDL_Renderer *renderer, const Bitboard *board) {
	//TODO: this is super slow, we should do startup once and then just have a rendering loop
	static SDL_Texture *sprites = NULL;
	static bool img_initted = false;

	if (!img_initted) {
		int init_flags = IMG_Init(IMG_INIT_PNG);
		if ((init_flags & IMG_INIT_PNG) == 0) {
			fprintf(stderr, "IMG_Init failed: %s\n", IMG_GetError());
			return;
		}
		img_initted = true;
	}

	if (sprites == NULL) {
		sprites = IMG_LoadTexture(renderer, "spritesheet.png");
		if (sprites == NULL) {
			fprintf(stderr, "IMG_LoadTexture failed: %s\n", IMG_GetError());
			return;
		}
	}

	SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
	SDL_RenderClear(renderer);

	for (int rank = 0; rank < BOARD_SIZE; ++rank) {
		for (int file = 0; file < BOARD_SIZE; ++file) {
			int idx = (rank * BOARD_SIZE) + file;
			int x = file * SQUARE_SIZE;
			int y = rank * SQUARE_SIZE;
			bool dark = ((rank + file) % 2) != 0;
			int square_tile = dark ? 0 : 1;

			draw_tile(renderer, sprites, square_tile, x, y);

			uint8_t value = board->squares[idx];
			uint8_t piece = (uint8_t)(value & 0x7F);
			if (piece != EMPTY && piece <= KING) {
				bool white = is_white(value);
				int piece_tile = white ? (piece + 7) : (piece + 1);
				draw_tile(renderer, sprites, piece_tile, x, y);
			}
		}
	}

	SDL_RenderPresent(renderer);
}

// END EDITS ALLOWED

int main(void) {
	if (SDL_Init(SDL_INIT_VIDEO) != 0) {
		fprintf(stderr, "SDL_Init failed: %s\n", SDL_GetError());
		return 1;
	}

	SDL_Window *window = SDL_CreateWindow(
			"Chess Driver", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
			WINDOW_SIZE, WINDOW_SIZE, SDL_WINDOW_SHOWN);
	if (window == NULL) {
		fprintf(stderr, "SDL_CreateWindow failed: %s\n", SDL_GetError());
		SDL_Quit();
		return 1;
	}

	SDL_Renderer *renderer =
			SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
	if (renderer == NULL) {
		fprintf(stderr, "SDL_CreateRenderer failed: %s\n", SDL_GetError());
		SDL_DestroyWindow(window);
		SDL_Quit();
		return 1;
	}

	Bitboard* board = malloc(sizeof(Bitboard));
	init_board(board);

	render_board(renderer, board);

	bool running = true;
	while (running) {
		SDL_Event event;
		if (SDL_WaitEvent(&event) == 0) {
			continue;
		}

		switch (event.type) {
		case SDL_QUIT:
			running = false;
			break;
		case SDL_MOUSEBUTTONDOWN:
			handle_click(board, event.button.x, event.button.y);
			render_board(renderer, board);
			break;
		default:
			break;
		}
	}

	SDL_DestroyRenderer(renderer);
	SDL_DestroyWindow(window);
	SDL_Quit();
	return 0;
}
