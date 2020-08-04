module main

// import rand
import gg
import gx
import math
import os
import sokol.sapp
import time
import vector2

// import danmaku_v.vector2
struct Game {
mut:
	gg              &gg.Context
	height          int
	width           int
	draw_fn         voidptr
	arrow_state     ArrowState
	bullets         []&Bullet
	player          &Player
	stgframe_width  int
	stgframe_height int
	ingame_player_x int
	ingame_player_y int
}

struct ArrowState {
mut:
	up    bool
	down  bool
	left  bool
	right bool
}

struct Bullet {
mut:
	pos   vector2.Vector2
	speed f32
	angle f32
	color gx.Color
}

struct Player {
mut:
	pos         vector2.Vector2
	speed       f32
	speed_slow	f32
	is_slowing  bool
	is_shooting bool
}

const (
	window_width  = 640
	window_height = 480
	bounds_left   = 32
	bounds_right  = 416
	bounds_top    = 16
	bounds_bottom = 464
	gameframe_w   = 384
	gameframe_h   = 448
	colors        = [
		gx.rgb(0, 0, 0), // black 0
		gx.rgb(255, 0, 0), // red 1
		gx.rgb(0, 255, 0), // green 2
		gx.rgb(0, 0, 255), // blue 3
		gx.rgb(255, 255, 0), // yellow 4
		gx.rgb(0, 255, 255), // cyan 5
		gx.rgb(255, 0, 255), // magenta 6
		gx.rgb(255, 255, 255), // white 7
		gx.rgba(0, 0, 255, 64), // transparent blue 8
	]
	text_cfg      = gx.TextCfg{
		color: gx.rgb(255, 255, 255)
		size: 24
		align: gx.align_right
	}
)

const (
	fpath = os.resource_abs_path('./assets/fonts/NANOTYPE.ttf')
)

fn main() {
	init_game()
}

fn init_game() {
	mut player := &Player{
		pos: vector2.new(gameframe_w / 2, bounds_bottom - 40)
		speed: 3.7
		speed_slow: 1.6
	}
	mut game := &Game{
		gg: 0
		height: window_height
		width: window_width
		stgframe_width: gameframe_w
		stgframe_height: gameframe_h
		player: player
		draw_fn: 0
	}
	game.gg = gg.new_context({
		width: window_width
		height: window_height
		font_size: 20
		use_ortho: true
		user_data: game
		window_title: 'Danmaku V'
		create_window: true
		frame_fn: frame
		event_fn: on_event
		font_path: fpath
		bg_color: gx.black
	})
	go game.run()
	go game.updater()
	game.gg.run()
}

fn frame(mut game Game) {
	game.gg.begin()
	game.renderer()
	game.gg.end()
}

fn (mut game Game) updater() {
	for {
		game.update_bullets()
		game.update_player()
		time.sleep_ms(17)
	}
}

fn (mut game Game) renderer() {
	// Player
	player_pos := game.player.pos
	game.gg.draw_rect(player_pos.x - 10, player_pos.y - 10, 20, 20, colors[5])
	// Bullet
	for i in 0 .. game.bullets.len {
		mut bullet := game.bullets[i]
		game.gg.draw_rect(bullet.pos.x + 32 - 5, bullet.pos.y + 16 - 5, 10, 10, bullet.color)
	}
	// UI
	game.draw_game_frame(bounds_left, bounds_right, bounds_top, bounds_bottom, colors[8])
	game.gg.draw_text(630, 450, 'Bullets: $game.bullets.len', text_cfg)
}

fn (mut game Game) run() {
	init_time := 60
	mut spawn_time := init_time
	for {
		if spawn_time < init_time {
			spawn_time++
		} else {
			spawn_time = 0
			game.shoot_circle(50)
		}
		time.sleep_ms(17) // 60fps
	}
}

fn (mut game Game) shoot_circle(density int) {
	if density > 0 {
		x := 0
		y := 0
		s := 2
		for i in 0 .. density {
			a := f32((i / f32(density)) * 360)
			game.create_bullet(x, y, s, a, colors[2])
		}
	} else {
		panic('Bullet density should be higher than 0')
	}
}

fn (mut game Game) create_bullet(x, y, speed, angle f32, color gx.Color) {
	pos := vector2.new(x, y)
	bullet := &Bullet{pos, speed, angle, color}
	game.bullets << bullet
}

fn (mut game Game) update_bullets() {
	for i in 0 .. game.bullets.len {
		mut bullet := game.bullets[i]
		if bullet.is_outofbound() {
			// remove bullet if bullet is out
			game.bullets.delete(i)
		} else {
			// Updating the bullet position, etc.
			x := bullet.pos.x + bullet.speed * math.cos(f32(bullet.angle) * (math.pi / 180))
			y := bullet.pos.y + bullet.speed * math.sin(f32(bullet.angle) * (math.pi / 180))
			bullet.pos.x = f32(x)
			bullet.pos.y = f32(y)
		}
	}
}

fn (mut bullet Bullet) is_outofbound() bool {
	pos := bullet.pos
	return pos.x < -32 || pos.x > (bounds_right) || pos.y < -32 || pos.y > (bounds_bottom)
}

fn (mut game Game) draw_game_frame(left, right, top, bottom int, color gx.Color) {
	game.gg.draw_rect(0, 0, left, window_height, color) // LEFT
	game.gg.draw_rect(right, 0, window_width - right, window_height, color) // RIGHT
	game.gg.draw_rect(0, 0, window_width, top, color) // TOP
	game.gg.draw_rect(0, bottom, window_width, window_height - bottom, color) // BOTTOM
}

fn (mut game Game) update_player() {
	mut speed := game.player.speed
	if game.player.is_slowing {
		speed = game.player.speed_slow
	}
	// Move based on ArrowState
	if game.arrow_state.up == true {
		game.player.pos.y -= speed
	} else if game.arrow_state.down == true {
		game.player.pos.y += speed
	}
	if game.arrow_state.left == true {
		game.player.pos.x -= speed
	} else if game.arrow_state.right == true {
		game.player.pos.x += speed
	}
}

fn on_event(e &sapp.Event, mut game Game) {
	match e.key_code {
		.left {
			if e.typ == .key_down {
				game.arrow_state.left = true
			}
			if e.typ == .key_up {
				game.arrow_state.left = false
			}
		}
		.right {
			if e.typ == .key_down {
				game.arrow_state.right = true
			}
			if e.typ == .key_up {
				game.arrow_state.right = false
			}
		}
		.up {
			if e.typ == .key_down {
				game.arrow_state.up = true
			}
			if e.typ == .key_up {
				game.arrow_state.up = false
			}
		}
		.down {
			if e.typ == .key_down {
				game.arrow_state.down = true
			}
			if e.typ == .key_up {
				game.arrow_state.down = false
			}
		}
		.left_shift {
			if e.typ == .key_down {
				game.player.is_slowing = true
			}
			if e.typ == .key_up {
				game.player.is_slowing = false
			}
		}
		else {}
	}
}

fn (mut game Game) key_down(key sapp.KeyCode) {
	match key {
		.escape { exit(0) }
		.left {}
		.right { game.arrow_state.right = false }
		.up { game.arrow_state.up = false }
		.down { game.arrow_state.down = false }
		else {}
	}
}

fn (mut game Game) key_up(key sapp.KeyCode) {
	match key {
		.left {}
		.right { game.arrow_state.right = true }
		.up { game.arrow_state.up = true }
		.down { game.arrow_state.down = true }
		else {}
	}
}
