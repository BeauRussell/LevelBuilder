package main

import "core:fmt"
import "core:math"
import "core:strings"
import "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
TILE_DIMENSION :: 32
TILE_ROW_LENGTH :: WINDOW_WIDTH / TILE_DIMENSION
TILE_COL_LENGTH :: WINDOW_HEIGHT / TILE_DIMENSION + 1
NUM_TILES :: TILE_ROW_LENGTH * TILE_COL_LENGTH 

main :: proc() {
    raylib.InitWindow(i32(WINDOW_WIDTH), i32(WINDOW_HEIGHT), "Level Builder")
    raylib.SetTargetFPS(60)
	raylib.SetTraceLogLevel(.ERROR)

	buff : [NUM_TILES]u8
	defer free(&buff)

	for !raylib.WindowShouldClose() {
		raylib.BeginDrawing()
		defer raylib.EndDrawing()

		raylib.ClearBackground(raylib.RAYWHITE)
		draw_grid(&buff)

		selected_tile := check_mouse_input()
		if selected_tile == -1 {
			continue
		}
		fmt.printf("Clicked box: %i\n", selected_tile)
	}
}

draw_grid :: proc(buff: ^[NUM_TILES]u8) {
	for i := 0; i < NUM_TILES; i += 1 {
		x := (i % TILE_ROW_LENGTH) * TILE_DIMENSION
		y := i / TILE_ROW_LENGTH * TILE_DIMENSION

		texture := load_texture(buff[i])
		raylib.DrawTexture(texture, i32(x), i32(y), raylib.WHITE)

		raylib.DrawRectangleLines(i32(x), i32(y), TILE_DIMENSION, TILE_DIMENSION, raylib.BLACK)
	}
}

check_mouse_input :: proc() -> int {
	if raylib.IsMouseButtonPressed(.LEFT) {
		mouse_coords := raylib.GetMousePosition()

		horizontal_index := int(math.floor(mouse_coords[0] / 32))
		vertical_index := int(math.floor(mouse_coords[1] / 32))

		return horizontal_index + (vertical_index * 40)
	}
	return -1
}

load_texture :: proc(id: u8) -> raylib.Texture {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	strings.write_string(&sb, "./assets/")
	strings.write_uint(&sb, uint(id))
	strings.write_string(&sb, ".png")
	file_path := strings.clone_to_cstring(strings.to_string(sb))

	image := raylib.LoadImage(file_path)
	defer raylib.UnloadImage(image)

	return raylib.LoadTextureFromImage(image)
}
