
struct Vector2 {
	x f32
	y f32
}

fn (a Vector2) add(b Vector2) Vector2 {
	return Vector2{
		x:a.x + b.x
		y:a.y + b.y
	}
}

fn main() {
	mut vec := Vector2{
		x: 5,
		y: 10
	}

	println("1st Vector:")
	println(vec)
	println("")

	mut vec2 := Vector2{
		x: 10,
		y: 10
	}

	println("2nd Vector:")
	println(vec2)
	println("")

	mut vec3 := vec.add(vec2)

	println("Add 1st with 2nd:")
	println(vec3)
}

