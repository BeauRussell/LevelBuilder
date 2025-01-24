package main

import "core:bufio"
import "core:fmt"
import "core:math"
import "core:os"
import "core:strings"
import "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
TILE_DIMENSION :: 32
TILE_ROW_LENGTH :: WINDOW_WIDTH / TILE_DIMENSION
TILE_COL_LENGTH :: WINDOW_HEIGHT / TILE_DIMENSION + 1
NUM_TILES :: TILE_ROW_LENGTH * TILE_COL_LENGTH 
TOTAL_TILES :: 9

main :: proc() {
    raylib.InitWindow(i32(WINDOW_WIDTH), i32(WINDOW_HEIGHT), "Level Builder")
    raylib.SetTargetFPS(60)
	raylib.SetTraceLogLevel(.ERROR)

	buff := read_stage_file(0)
	change_tile_open := false
	drawing_tile_id := u8(0)
	safe_to_draw: bool

	for !raylib.WindowShouldClose() {
		defer free_all(context.temp_allocator)
		raylib.BeginDrawing()
		defer raylib.EndDrawing()

		draw_grid(buff[:])
		switch_state := draw_select_tile_text(&change_tile_open)
		click_on_change_window: bool
		if change_tile_open {
			click_on_change_window = draw_select_tile_menu(&drawing_tile_id, &change_tile_open, switch_state, &safe_to_draw)
		}
		if switch_state || change_tile_open {
			continue
		}

		check_change_tile(drawing_tile_id, 0, buff[:], &safe_to_draw)
	}
}

draw_grid :: proc(buff: []u8) {
	for i := 0; i < NUM_TILES; i += 1 {
		x := (i % TILE_ROW_LENGTH) * TILE_DIMENSION
		y := i / TILE_ROW_LENGTH * TILE_DIMENSION

		texture := load_texture(buff[i])
		raylib.DrawTexture(texture, i32(x), i32(y), raylib.WHITE)

		raylib.DrawRectangleLines(i32(x), i32(y), TILE_DIMENSION, TILE_DIMENSION, raylib.WHITE)
	}
}

draw_select_tile_text :: proc(change_tile_open: ^bool) -> bool {
	rect := raylib.Rectangle{
		x = 10,
		y = WINDOW_HEIGHT - 20,
		width = 55,
		height = 12,
	}
	raylib.DrawRectangleRec(rect, raylib.BLANK)
	textColor := raylib.BLACK

	if raylib.CheckCollisionPointRec(raylib.GetMousePosition() , rect) {
		if raylib.IsMouseButtonPressed(.LEFT) {
			change_tile_open^ = !change_tile_open^
			return true
		}
		textColor = raylib.DARKGRAY
	}

	raylib.DrawText("Select Tile", 10, WINDOW_HEIGHT - 20, 6, textColor)
	return false
}

draw_select_tile_menu :: proc(selected_id: ^u8, change_tile_open: ^bool, just_opened: bool, safe_to_draw: ^bool) -> bool {
	menu_rect := raylib.Rectangle{
		x = 10,
		y = WINDOW_HEIGHT - 240,
		width = 220,
		height = 220,
	}
	menu_color := raylib.Color{
		200,
		200,
		200,
		175,
	}
	
	raylib.DrawRectangleRec(menu_rect, menu_color)
	collideable_rects : [TOTAL_TILES]raylib.Rectangle

	for i := 0; i < TOTAL_TILES; i += 1 {
		x := menu_rect.x + 50 + f32(40 * (i % 3))
		y := menu_rect.y + 50 + f32(40 *  (i / 3) ) 
		collide_box_color := raylib.BLANK
		collide_box := raylib.Rectangle{
			x = x - 5,
			y = y - 5,
			width = 42,
			height = 42,
		}
		collideable_rects[i] = collide_box
		if u8(i) == selected_id^ {
			collide_box_color = raylib.BLUE
		}

		raylib.DrawRectangleRec(collide_box, collide_box_color)
		tile := load_texture(u8(i))
		raylib.DrawTexture(tile, i32(x), i32(y), raylib.WHITE)
	}

	if raylib.CheckCollisionPointRec(raylib.GetMousePosition(), menu_rect) && raylib.IsMouseButtonPressed(.LEFT) {
		check_if_new_selected_tile(selected_id, collideable_rects)
		return true
	} else if raylib.IsMouseButtonPressed(.LEFT) && !raylib.CheckCollisionPointRec(raylib.GetMousePosition(), menu_rect) && !just_opened {
		change_tile_open^ = false
		safe_to_draw^ = false
		return true
	}
	return false
}

check_if_new_selected_tile :: proc(selected_id: ^u8, rects: [TOTAL_TILES]raylib.Rectangle) {
	for rect, idx in rects {
		if raylib.CheckCollisionPointRec(raylib.GetMousePosition(), rect) {
			selected_id^ = u8(idx)
		}
	}
}

check_change_tile :: proc(change_tile: u8, stage_id: u8, stage_data: []u8, safe_to_draw: ^bool) {
	if raylib.IsMouseButtonReleased(.LEFT) {
		safe_to_draw^ = true
	}
	if raylib.IsMouseButtonDown(.LEFT) && safe_to_draw^ {
		mouse_coords := raylib.GetMousePosition()

		horizontal_index := int(math.floor(mouse_coords[0] / 32))
		vertical_index := int(math.floor(mouse_coords[1] / 32))

		selected_tile := horizontal_index + (vertical_index * 40)
		if stage_data[selected_tile] != change_tile {
			stage_data[selected_tile] = change_tile 
			write_stage_file(stage_id, stage_data)
		}
	}
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

read_stage_file :: proc(id: u8) -> [NUM_TILES]u8 {
	stage: [NUM_TILES]u8

	f, ferr := os.open(build_stage_file_path(id), os.O_RDONLY, 0o666)
	if ferr != nil {
		fmt.printf("Stage file failed to open for id %i, using new buffer: %v\n", id, os.error_string(ferr))
		return stage
	}
	defer os.close(f)

	r: bufio.Reader
	bufio.reader_init_with_buf(&r, os.stream_from_handle(f), stage[:])
	defer bufio.reader_destroy(&r)

	bufio.reader_read(&r, stage[:])

	return stage
}

write_stage_file :: proc(id: u8, stage_data: []u8) -> bool {
	if ok := os.is_dir("./stages"); ok != true {
		os.make_directory("./stages")
	}

	f, ferr := os.open(build_stage_file_path(id), os.O_CREATE|os.O_WRONLY, 0o666)
	if ferr != nil {
		fmt.printf("Stage file failed to open for id %i: %s\n", id, os.error_string(ferr))
		return false
	}
	defer os.close(f)

	_, werr := os.write(f, stage_data)
	if werr != nil {
		fmt.printf("Failed to write new stage data to file for id %i: %s\n", id, os.error_string(werr))
		return false
	}

	return true 
}

build_stage_file_path :: proc(id: u8) -> string {
	return fmt.tprintf("./stages/%v.dat", id)
}
