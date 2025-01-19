package main

import "core:fmt"
import "core:math"
import "core:strings"
import "vendor:raylib"

WINDOW_WIDTH : i32 : 1280
WINDOW_HEIGHT : i32 : 720

main :: proc() {
    raylib.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Level Builder")
    raylib.SetTargetFPS(60)

	buff : [920]u8

	for !raylib.WindowShouldClose() {
		raylib.BeginDrawing()
		defer raylib.EndDrawing()

		raylib.ClearBackground(raylib.RAYWHITE)
		draw_grid()

		selected_tile := check_mouse_input()
		if selected_tile == -1 {
			continue
		}
		fmt.printf("Clicked box: %i\n", selected_tile)
	}
}

draw_grid :: proc() {
	for i := 0; i < 40; i += 1 {
		x := 32 * i
		raylib.DrawLine(i32(x), 0, i32(x), WINDOW_HEIGHT, raylib.BLACK)
	}
	for i := 0; i < 40; i += 1 {
		y := 32 * i
		raylib.DrawLine(0, i32(y), WINDOW_WIDTH, i32(y), raylib.BLACK)
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
