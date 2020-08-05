module main

// import rand
import gg
import gx
import math
import os
import sokol.sapp
import rand
import time
import collision
import vector2

// import danmaku_v.vector2
struct Game {
mut:
	gg              &gg.Context
	height          int
	width           int
	draw_fn         voidptr
	arrow_state     &ArrowState
	player          &Player
	boss			&Boss
	bullets         []&Bullet
	player_bullets  []&Bullet
	stgframe_width  int
	stgframe_height int
	ingame_player_x int
	ingame_player_y int
}

struct ArrowState {
mut:
	up    bool = false
	down  bool = false
	left  bool = false
	right bool = false
}

enum BulletOwner {
	player
	enemy
}

struct Bullet {
mut:
	pos      vector2.Vector2
	speed    f32
	angle    f32
	color    gx.Color
	grazed   bool = false
	owner    BulletOwner
	collider collision.Collision
}

struct Player {
mut:
	pos             vector2.Vector2
	speed           f32
	speed_slow      f32
	is_slowing      bool
	is_shooting     bool
	shoot_delay     int
	shoot_delay_max int
	lifes           int
	grazes          int
	invisible_time	int
	collider        collision.Collision
	graze_collider  collision.Collision
}

struct Boss {
mut:
	pos        vector2.Vector2
	health     int
	max_health int
	collider   collision.Collision
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
	text_cfg2     = gx.TextCfg{
		color: gx.rgb(255, 255, 255)
		size: 32
		align: gx.align_left
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
		shoot_delay: 0
		shoot_delay_max: 3
		lifes: 999
		invisible_time: 300
		collider: collision.new(1)
		graze_collider: collision.new(10)
	}
	mut boss := &Boss{
		pos: vector2.new(0, 0)
		health: 5000
		max_health: 5000
		collider: collision.new(20)
	}
	mut game := &Game{
		gg: 0
		height: window_height
		width: window_width
		stgframe_width: gameframe_w
		stgframe_height: gameframe_h
		player: player
		boss: boss
		draw_fn: 0
		arrow_state: &ArrowState{false, false, false, false}
	}
	game.gg = gg.new_context({
		width: window_width
		height: window_height
		font_size: 20
		use_ortho: true
		user_data: game
		window_title: 'Touhou Danmaku V'
		create_window: true
		resizable: false
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
		game.update_player_bullets()
		game.update_bullets()
		game.update_player()
		game.update_boss()
		time.sleep_ms(17)
	}
}

fn (mut game Game) bullet_updater() {
	for {
		game.update_bullets()
		time.sleep_ms(17)
	}
}

fn (mut game Game) renderer() {
	// Boss
	game.render_boss() 
	// Player Bullet
	for i in 0 .. game.player_bullets.len {
		mut bullet := game.player_bullets[i]
		game.gg.draw_rect(bullet.pos.x + 32 - 2.5, bullet.pos.y + 16 - 5, 5, 10, bullet.color)
	}
	// Player
	game.render_player()
	// Bullet
	for i in 0 .. game.bullets.len {
		mut bullet := game.bullets[i]
		game.gg.draw_rect(bullet.pos.x + 32 - 5, bullet.pos.y + 16 - 5, 10, 10, bullet.color)
	}
	// UI
	game.draw_game_frame(bounds_left, bounds_right, bounds_top, bounds_bottom, colors[8])
	game.gg.draw_text(630, 450, 'Bullets: $game.bullets.len', text_cfg)
	game.gg.draw_text(bounds_right + 20, 80, 'Player: $game.player.lifes', text_cfg2)
	game.gg.draw_text(bounds_right + 20, 120, 'Boss: $game.boss.health / $game.boss.max_health', text_cfg2)
}

fn (mut game Game) run() {

	// Doing ObjMove_SetDestAtFrame from Danmakufu	
	mut at_frame := 60
	mut destination := vector2.new(gameframe_w / 2, 120)
	mut distance := destination.distance(game.boss.pos)
	mut direction := destination.angle(game.boss.pos)
	mut step := f32(distance / at_frame)
	for math.round(destination.distance(game.boss.pos)) > 0 {
		game.boss.pos.x += f32(step * math.cos(direction))
		game.boss.pos.y += f32(step * math.sin(direction))
		time.sleep_ms(17)
	}

	time.sleep_ms(1500)
	for {
		game.shoot_circle(50)
		time.sleep_ms(750)
	}
}

fn (mut game Game) shoot_circle(density int) {
	init_rot := rand.intn(359)
	if density > 0 {
		x := game.boss.pos.x
		y := game.boss.pos.y
		s := 2
		for i in 0 .. density {
			a := f32((i / f32(density)) * 360) + init_rot
			game.create_bullet(x, y, s, a, colors[2])
		}
	} else {
		panic('Bullet density should be higher than 0')
	}
}

fn (mut game Game) create_bullet(x, y, speed, angle f32, color gx.Color) {
	bullet := &Bullet{
		pos: vector2.new(x, y)
		speed: speed
		angle: angle
		color: color
		owner: BulletOwner.enemy
		collider: collision.new(5)
	}
	game.bullets << bullet
}

fn (mut game Game) update_bullets() {
	if game.bullets.len > 0 {
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
				bullet.collider.pos.x = f32(x)
				bullet.collider.pos.y = f32(y)
			}
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

fn (mut game Game) create_player_bullet(x, y, speed, angle f32, color gx.Color) {
	bullet := &Bullet{
		pos: vector2.new(x, y)
		speed: speed
		angle: angle
		color: color
		owner: BulletOwner.player
		collider: collision.new(5)
	}
	game.player_bullets << bullet
}

fn (mut game Game) render_player() {
	player_pos := game.player.pos
	if game.player.invisible_time > 0 {
		game.player.invisible_time--
		if (game.player.invisible_time / 3) % 2 == 0 {
			game.gg.draw_rect(player_pos.x + 32 - 10, player_pos.y + 16 - 10, 20, 20, colors[5])
		}
		else {
			game.gg.draw_rect(player_pos.x + 32 - 10, player_pos.y + 16 - 10, 20, 20, colors[1])
		}
	}
	else {
		game.gg.draw_rect(player_pos.x + 32 - 10, player_pos.y + 16 - 10, 20, 20, colors[5])
	}
	if game.player.is_slowing == true {
		game.gg.draw_rect(player_pos.x + 32 - 2, player_pos.y + 16 - 2, 4, 4, colors[1])
	}
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
	// When Hit bounds
	if game.player.pos.x < 10 {
		game.player.pos.x = 10
	}
	if game.player.pos.x > gameframe_w - 10 {
		game.player.pos.x = gameframe_w - 10
	}
	if game.player.pos.y < 10 {
		game.player.pos.y = 10
	}
	if game.player.pos.y > gameframe_h - 10 {
		game.player.pos.y = gameframe_h - 10
	}
	// Update player collision box
	game.player.collider.pos.x = f32(game.player.pos.x)
	game.player.collider.pos.y = f32(game.player.pos.y)
	go game.check_player_collision()
	// Shoot
	if game.player.is_shooting == true {
		if game.player.shoot_delay > 0 {
			game.player.shoot_delay--
		} else {
			game.create_player_bullet(game.player.pos.x - 7, game.player.pos.y, 28, 270,
				gx.white)
			game.create_player_bullet(game.player.pos.x + 7, game.player.pos.y, 28, 270,
				gx.white)
			game.player.shoot_delay = game.player.shoot_delay_max
		}
	} else {
		game.player.shoot_delay = 0
	}
}

fn (mut game Game) check_player_collision() {
	if game.player.invisible_time == 0 {
		for i in 0 .. game.bullets.len {
			mut bullet := game.bullets[i]
			if bullet.collider.check(game.player.collider) {
				game.bullets.delete(i)
				game.player.lifes--
				game.player.invisible_time = 300
			}
		}
	}
}

fn (mut game Game) update_player_bullets() {
	if game.player_bullets.len > 0 {
		for i in 0 .. game.player_bullets.len {
			mut bullet := game.player_bullets[i]
			if bullet.is_outofbound() {
				// remove bullet if bullet is out
				game.player_bullets.delete(i)
			} else {
				// Updating the bullet position, etc.
				x := bullet.pos.x + bullet.speed * math.cos(f32(bullet.angle) * (math.pi / 180))
				y := bullet.pos.y + bullet.speed * math.sin(f32(bullet.angle) * (math.pi / 180))
				bullet.pos.x = f32(x)
				bullet.pos.y = f32(y)
				bullet.collider.pos.x = f32(x)
				bullet.collider.pos.y = f32(y)
			}
		}
	}
}

fn (mut game Game) update_boss() {
	game.boss.collider.pos.x = f32(game.boss.pos.x)
	game.boss.collider.pos.y = f32(game.boss.pos.y)
	game.check_boss_collision()
}

fn (mut game Game) check_boss_collision() {
	for i in 0 .. game.player_bullets.len {
		mut bullet := game.player_bullets[i]
		if bullet.collider.check(game.boss.collider) {
			game.player_bullets.delete(i)
			game.boss.health -= 10
		}
	}
}

fn (mut game Game) render_boss() {
	boss_pos := game.boss.pos
	game.gg.draw_rect(boss_pos.x + 32 - 15, boss_pos.y + 16 - 15, 30, 30, colors[5])
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
		.z {
			if e.typ == .key_down {
				game.player.is_shooting = true
			}
			if e.typ == .key_up {
				game.player.is_shooting = false
			}
		}
		else {}
	}
}
