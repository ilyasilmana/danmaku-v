
module main

import vector2

fn main() {
	mut vec := vector2.new(5, 10)

	println('1st Vector:')
	println(vec)
	println('')

	mut vec2 := vector2.new(10, 10)

	println('2nd Vector:')
	println(vec2)
	println('')

	mut vec3 := vec.add(vec2)
  mut mag := vec3.magnitude()

	println('Vector 3 = Vector 1 + Vector 2')
	println(vec3)
	println('')

	println('Magnitude of Vector 3')
	println(mag)
	println('')

  vec3 = vec3.add(vector2.down)
  mag = vec3.magnitude()

	println('Add Vector2.Down (shorthand for Vector2{0, -1}) to Vector3')
	println(vec3)
	println('')

	println('Magnitude of Vector 3 after addition')
	println(mag)
	println('')

	println('Normalized Vector 3')
	println(vec3.normalize())
	println('')
}

