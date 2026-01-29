// BEGIN EDITS ALLOWED

#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

const uint8_t EMPTY = 0;
const uint8_t PAWN = 1;
const uint8_t KNIGHT = 2;
const uint8_t BISHOP = 3;
const uint8_t ROOK = 4;
const uint8_t QUEEN = 5;
const uint8_t KING = 6;
const uint8_t WHITE_TAG = 0x80;
const uint8_t ALLOWED_TAG = 0x40;
const uint8_t PIECE_DATA_MASK = 0x07;

const int BOARD_SIDE_SIZE = 8;
const int SQUARE_SIZE_PX = 32;
const int WINDOW_SIZE = BOARD_SIDE_SIZE * SQUARE_SIZE_PX;
const int SELECTED_TILE_INDEX_OFFSET = 14;
const int ALLOWED_TILE_INDEX_OFFSET = 16;

typedef struct {
	uint8_t squares[BOARD_SIDE_SIZE * BOARD_SIDE_SIZE];
} Bitboard;

extern void init_board(Bitboard *board);
extern void click(Bitboard* board, uint8_t rank, uint8_t file);
extern uint8_t selected_rank;
extern uint8_t selected_file;

static void handle_click(Bitboard *board, int mouse_x, int mouse_y) {
	uint8_t file = mouse_x / SQUARE_SIZE_PX;
	uint8_t rank = 7 - (mouse_y / SQUARE_SIZE_PX);
	if (file >= BOARD_SIDE_SIZE || rank >= BOARD_SIDE_SIZE) {
		return;
	}
	// TODO: we might want to use this instead of rank/file at some point
	// int idx = (rank * BOARD_SIDE_SIZE) + file;
	click(board, rank, file);
}

// helper function for rendering
static int is_white(uint8_t piece) {
	return piece & WHITE_TAG;
}

static int allowed(const Bitboard* board, int idx) {
	return board->squares[idx] & ALLOWED_TAG;
}

static void draw_tile(SDL_Renderer *renderer, SDL_Texture *sprites, int tile_index, int x, int y) {
	SDL_Rect src = {tile_index * SQUARE_SIZE_PX, 0, SQUARE_SIZE_PX, SQUARE_SIZE_PX};
	SDL_Rect dst = {x, y, SQUARE_SIZE_PX, SQUARE_SIZE_PX};
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

	for (int rank = 0; rank < BOARD_SIDE_SIZE; ++rank) {
		for (int file = 0; file < BOARD_SIDE_SIZE; ++file) {
			int idx = (rank * BOARD_SIDE_SIZE) + file;
			// printf("%i %i %i\n", rank, file, board->squares[idx]);
			int x = file * SQUARE_SIZE_PX;
			// flip ts shit
			int y = WINDOW_SIZE - ((rank + 1) * SQUARE_SIZE_PX);
			bool dark = ((rank + file) % 2) != 0;

			int tile_index = dark ? 0 : 1;
			if(rank == selected_rank && file == selected_file) tile_index += SELECTED_TILE_INDEX_OFFSET;
			else if(allowed(board, idx)) {
				tile_index += ALLOWED_TILE_INDEX_OFFSET;
			}

			draw_tile(renderer, sprites, tile_index, x, y);
			
			uint8_t piece = board->squares[idx];
			// mask away white tag (if it exists)
			uint8_t piece_without_color = (uint8_t)(board->squares[idx] & PIECE_DATA_MASK);
			if(piece_without_color > KING) {
				fprintf(stderr, "invalid piece data at idx %i", idx);
				return;
			}

			if (piece_without_color != EMPTY) {
				int piece_tile = is_white(piece) ? (piece_without_color + 7) : (piece_without_color + 1);
				draw_tile(renderer, sprites, piece_tile, x, y);
			}
		}
	}

	SDL_RenderPresent(renderer);
}

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
