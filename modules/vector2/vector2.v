// Vector2 Library
// Inspired by Unity's Vector2

module vector2

import math

struct C.math{}

pub struct Vector2 {
pub mut:
	x f32
	y f32
}

pub const (
	up    = Vector2{0, 1}
	down  = Vector2{0, -1}
	right = Vector2{0, 1}
	left  = Vector2{-1, 0}
)

// Create new Vector2 Object (as I call it)
pub fn new(x, y f32) Vector2 {
	return Vector2{
		x: x
		y: y
	}
}

// Add a vector with other vector
pub fn (a Vector2) add(b Vector2) Vector2 {
	return Vector2{
		x: a.x + b.x
		y: a.y + b.y
	}
}

// Subtract a vector with other vector
pub fn (a Vector2) sub(b Vector2) Vector2 {
	return Vector2{
		x: a.x - b.x
		y: a.y - b.y
	}
}

// Multiply Vector by value
pub fn (a Vector2) mul(b f32) Vector2 {
  return Vector2{
    x: a.x * b
    y: a.y * b
  }
}

// Angle between a and b, returned as radians
pub fn (a Vector2) angle(b Vector2) f32 {
	return f32(math.atan2((a.y - b.y), (a.x - b.x)))
}

// Distance between a and b
pub fn (a Vector2) distance(b Vector2) f32 {
	return a.sub(b).magnitude()
}

// Dot product a vector with other
pub fn (a Vector2) dot_product(b Vector2) f32 {
  return (a.x * b.x) + (a.y * b.y)
}

// Get vector magnitude
pub fn (a Vector2) magnitude() f32 {
  return math.powf((a.x * a.x) + (a.y * a.y), 0.5)
}

// Get normalized vector
pub fn (a Vector2) normalize() Vector2 {
  mag := math.powf((a.x * a.x) + (a.y * a.y), 0.5)
  return Vector2{
    x: a.x / mag,
    y: a.y / mag
  }
}
