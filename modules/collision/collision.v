module collision

import vector2

pub struct Collision {
pub mut:
	pos vector2.Vector2
	rad f32
}

pub fn new(rad f32) Collision {
	return Collision{
		pos: vector2.new(0, 0)
		rad: rad
	}
}

pub fn (mut col Collision) uncollide_minimum(mut other Collision) f32 {
	return (col.rad + other.rad)
}

pub fn (mut col Collision) check(mut other Collision) bool {
	return other.pos.distance(col.pos) < (col.rad + other.rad)
}

pub fn (mut col Collision) distance(mut other Collision) f32 {
	return other.pos.distance(col.pos)
}
