attribute vec2 p;
void main() {
	gl_Position = vec4(p, 0.0, 1.0); // p is a xy coord, we dont have z, last one is w for 3d to 2d projection and distance i think (vertex is far away from cam = high w, etc.)
}

