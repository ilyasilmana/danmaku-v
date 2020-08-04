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
	bullets         []&Bullet
	stgframe_width  int
	stgframe_height int
	frame           int
	frame_old       int
	fps				f64
	frame_sw        time.StopWatch = time.new_stopwatch({})
	second_sw       time.StopWatch = time.new_stopwatch({})
}

struct Bullet {
mut:
	pos   vector2.Vector2
	speed f32
	angle f32
	color gx.Color
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
	mut game := &Game{
		gg: 0
		stgframe_width: gameframe_w
		stgframe_height: gameframe_h
		height: window_height
		width: window_width
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
	game.showfps()
	game.gg.end()
}

fn (mut game Game) showfps() {
	game.frame++
	ticks := f64(game.second_sw.elapsed().microseconds()) / 1000.0
	if ticks > 999.0 {
		game.fps = f64(game.frame - game.frame_old) * ticks / 1000.0
		game.second_sw.restart()
		game.frame_old = game.frame
	}

	game.gg.draw_text(630, 430, 'FPS: ${game.fps:5.1f}', text_cfg)
}

fn (mut game Game) renderer() {
	// Bullet
	for i in 0 .. game.bullets.len {
		mut bullet := game.bullets[i]
		// if bullet.is_outofbound() == false {
		game.gg.draw_rect(bullet.pos.x + 32, bullet.pos.y + 16, 10, 10, bullet.color)
		// }
	}
	// UI
	game.draw_game_frame(bounds_left, bounds_right, bounds_top, bounds_bottom, colors[8])
	game.gg.draw_text(630, 450, 'Bullets: $game.bullets.len', text_cfg)
}

fn (mut game Game) updater() {
	for {
		game.update_bullets()
		time.sleep_ms(17)
	}
}

fn (mut game Game) run() {
	init_time := 3
	mut spawn_time := init_time
	for {
		if spawn_time < init_time {
			spawn_time++
		} else {
			spawn_time = 0
			game.shoot_circle(500)
		}
		time.sleep_ms(17) // 60fps
	}
}

fn (mut game Game) shoot_circle(density int) {
	if density > 0 {
		x := game.stgframe_width / 2
		y := 0
		s := 3
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

fn on_event(e &sapp.Event, mut game Game) {
	if e.typ == .key_down {
		key_code := e.key_code
		match key_code {
			.escape { exit(0) }
			else {}
		}
	}
}
