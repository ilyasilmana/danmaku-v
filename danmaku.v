module main

import gg
import gx
import math
import rand
import time
import vector2

// import danmaku_v.vector2
struct Game {
mut:
	gg      &gg.Context
	height  int
	width   int
	draw_fn voidptr
	bullets []&Bullet
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
	bounds_left   = 0
	bounds_top    = 0
	bounds_right  = 640
	bounds_bottom = 480
	colors        = [
		gx.rgb(0, 0, 0), // black
		gx.rgb(255, 0, 0), // red
		gx.rgb(0, 255, 0), // green
		gx.rgb(0, 0, 255), // blue
		gx.rgb(255, 255, 0), // yellow
		gx.rgb(0, 255, 255), // cyan
		gx.rgb(255, 0, 255), // magenta
		gx.rgb(255, 255, 255), // white
	]
)

fn main() {
	init_game()
}

fn init_game() {
	mut game := &Game{
		gg: 0
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
		bg_color: gx.black
	})
	go game.run()
	game.gg.run()
}

fn frame(mut game Game) {
	game.gg.begin()
	game.update_bullets()
	println(game.bullets.len)
	game.gg.end()
}

fn (mut game Game) run() {
	init_time := 2
	mut spawn_time := init_time
	init_time2 := 60
	mut spawn_time2 := init_time2
	init_time3 := 20
	mut spawn_time3 := init_time3
	for {
		if spawn_time < init_time {
			spawn_time++
		} else {
			spawn_time = 0
			x := 320
			y := 240
			s := rand.f32n(3) + 1
			a := rand.f32n(359)
			game.create_bullet(x, y, s, a, colors[1])
		}
		if spawn_time2 < init_time2 {
			spawn_time2++
		} else {
			spawn_time2 = 0
			game.shoot_circle(50)
		}
		if spawn_time3 < init_time3 {
			spawn_time3++
		} else {
			spawn_time3 = 0
			game.shoot_long(7, 1.5, 0.5)
		}
		time.sleep_ms(17) // 60fps
	}
}

fn (mut game Game) shoot_circle(density int) {
	if density > 0 {
		x := 320
		y := 240
		s := 2
		for i in 0 .. density {
			a := f32((i / f32(density)) * 360)
			game.create_bullet(x, y, s, a, colors[2])
		}
	} else {
		panic('Bullet density should be higher than 0')
	}
}

fn (mut game Game) shoot_long(count int, base_speed, acceleration f32) {
	if count > 0 {
		x := 320
		y := 240
		a := rand.f32n(359)
		for i in 0 .. count {
			s := base_speed + (i * acceleration)
			game.create_bullet(x, y, s, a, colors[6])
		}
	} else {
		panic('Bullet count should be higher than 0')
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
			// Drawing the bullet
			game.gg.draw_rect(bullet.pos.x, bullet.pos.y, 10, 10, bullet.color)
		}
	}
}

fn (mut bullet Bullet) is_outofbound() bool {
	pos := bullet.pos
	return pos.x < bounds_left ||
		pos.x > bounds_right || pos.y < bounds_top || pos.y > bounds_bottom
}
