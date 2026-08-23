// -1. Input Search

const search = document.querySelector('input');
console.log('search element:', search);
search.addEventListener('keydown', e => {
	console.log('key pressed:', e.key, 'value:', e.target.value);
	if (e.key === 'Enter' && e.target.value.trim()) {
		location.href = 'https://duckduckgo.com/?q=' + encodeURIComponent(e.target.value);
	}
});

// 0. Load Shaders

async function loadShaders() {
	const [vert, frag] = await Promise.all([
		fetch('shaders/wave.vert').then(r => {
			if (!r.ok) throw new Error('missing wave.vert');
			return r.text()
		}
		),
		fetch('shaders/wave.frag').then(r => {
			if (!r.ok) throw new Error('missing wave.frag');
			return r.text()
		}
		),
	]);
  return { vert, frag };
}

// 1. clock + date
var clock = document.getElementById("clock");
var date = document.getElementById("date");
var greeting = document.getElementById('greeting');

function returnGreeting(hours) {
	switch (true) {
		case hours >= 19:
			return "こんばんは"
		case hours >= 12:
			return "こんにちは"
		case hours >= 6:
			return "おはようございます"
		case hours >= 0:
			return "まだ起きてる？"
		default:
			break;
	}
}

function updateTime() {
	const now = new Date();
	let hours = now.getHours();
	const time = now.toLocaleTimeString("en-DE", {hour: "2-digit", minute: "2-digit"});
	const dateString = now.toLocaleDateString("en-DE", {
		weekday: "long", day: "numeric", month: "long"
	});

	switch (true) {
		case hours >= 12:

	}

	greeting.textContent = `${returnGreeting(hours)}、ラモ`;
	clock.innerHTML = time;
	date.textContent = dateString;
}

setInterval(updateTime, 1000);
updateTime();

// 2. readPalette()
function hexToRGB(hex) {
	hex = hex.replace('#', ''); // remove #
	if (hex.length === 3) {
		hex = hex[0]+hex[0] + hex[1]+hex[1] + hex[2]+hex[2]; // double it and give it to the next person: abc --> aabbcc
	}
	const n = parseInt(hex, 16); // Parse as a hex value --> convert into integer in form of a REAL hex value e.g. 0xaabbcc (11189196, but thats wayne, we are working with byte position)
	return [
		((n >> 16) & 255) / 255, // Shift aa bb cc 2 Bytes to the right = (00 00 aa) && (00 00 ff) (255) ==> aa remains as value, divide by 255 to get value between 0 and 1 = RED VALUE
		((n >>  8) & 255) / 255, // Shift aa bb cc 1 Byte to the right = (00 aa bb) && (00 00 ff) (255) ==> bb remains as value, divide by 255 to get value between 0 and 1 = GREEN VALUE
		( n        & 255) / 255, // Shift aa bb cc 0 Bytes to nothign = (aa bb cc) && (00 00 ff) (255) => cc remains as value, divide by 255 to get value between 0 and 1 = BLUE VALUE
	]; // Return an array for RGB values (3 values) --> need vec3 to display the color
}

function readPalette() {
	const s = getComputedStyle(document.documentElement);
	const get = (name, fallback) =>
		hexToRGB(s.getPropertyValue(name).trim() || fallback);

	return {
		surface:  get('--m-surface',  '#1a1114'),
		primary:  get('--m-primary',  '#f0a8c0'),
		tertiary: get('--m-tertiary', '#a8b8e0'),
	};
}
// 3. initGL()           -> compile, link, buffer, uniform locations
function initGL(vert, frag) {
	const canvas = document.getElementById('gl');
	const gl = canvas.getContext('webgl', { antialias: false, alpha: false });
	if (!gl) throw new Error('no webgl');

	// compile
	function compile(type, src) {
		const s = gl.createShader(type);
		gl.shaderSource(s, src);
		gl.compileShader(s);
		if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) {
			throw new Error(gl.getShaderInfoLog(s));
		}
		return s;
	}

	const vertexShader   = compile(gl.VERTEX_SHADER, vert);
	const fragmentShader = compile(gl.FRAGMENT_SHADER, frag);

	// link
	const prog = gl.createProgram();
	gl.attachShader(prog, vertexShader);
	gl.attachShader(prog, fragmentShader);

	gl.linkProgram(prog);
	if (!gl.getProgramParameter(prog, gl.LINK_STATUS)) {
		throw new Error(gl.getProgramInfoLog(prog));
	}
	gl.useProgram(prog);

	// geometry, we need an object where we can apply a fragment shader on (its a big triangle convering the whole screen)
	gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer()); // allocate + select this buffer (space)
	gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1,-1,3,-1,-1,3]), gl.STATIC_DRAW); // do thing on space, in this case create a triangle from 3 coordinates (2 vals per coord)
	const p = gl.getAttribLocation(prog, 'p'); // get p variable from vertex shader (program has both in them)
	gl.enableVertexAttribArray(p); // turn attribtue on (it will now pull fresh value from buffer for each vertex instead of being a fixed value in off mode)
	gl.vertexAttribPointer(p, 2, gl.FLOAT, false, 0, 0); // for each vertex get 2 values from the list as one vertex

	// uniform handles, look it up once and use it all the time - otherwise it would need to lookup every run
	const u = {
		res:      gl.getUniformLocation(prog, 'uRes'),
		time:     gl.getUniformLocation(prog, 'uT'),
		surface:  gl.getUniformLocation(prog, 'uSurface'),
		primary:  gl.getUniformLocation(prog, 'uPrimary'),
		tertiary: gl.getUniformLocation(prog, 'uTertiary'),
	};

	// sizing
	function resize() {
		const dpr = 0.5; // Save some ressources
		canvas.width  = Math.floor(canvas.clientWidth  * dpr);
		canvas.height = Math.floor(canvas.clientHeight * dpr);
		gl.viewport(0, 0, canvas.width, canvas.height);
		gl.uniform2f(u.res, canvas.width, canvas.height);
	}
	window.addEventListener('resize', resize);
	resize();

	return { gl, u, resize };
}

// 4. uploadPalette()    -> gl.uniform3fv x3 = uniforms are basically constants in the shader program (you can change them after every run tho) => we update them with new palette value
function uploadPalette(gl, u) {
	const pal = readPalette();
	gl.uniform3fv(u.surface,  pal.surface); 
	gl.uniform3fv(u.primary,  pal.primary);
	gl.uniform3fv(u.tertiary, pal.tertiary);
}

// Statup
const { vert, frag } = await loadShaders();
const { gl, u } = initGL(vert, frag);
uploadPalette(gl, u);

// 6. frame loop
let raf = null;
let last = 0;
const start = performance.now();
const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;

function frame(now) {
	raf = requestAnimationFrame(frame); // Tell Browser to run this on next frame
	if (now - last < 33) return;        // Skip if between now and last is less then 33ms (about 30fps)
	last = now;				// now is the last point we generated a fram
	gl.uniform1f(u.time, (now - start) / 1000); // 3500ms since page load, start script after page load = 3500ms - 200ms delay = 3300ms Since the Animation began
	gl.drawArrays(gl.TRIANGLES, 0, 3); // Draw new frame
}

document.addEventListener('visibilitychange', () => {
	if (document.hidden) {
		cancelAnimationFrame(raf); // dont render when its not loading
		raf = null;
	} else if (!raf && !reduced) {
		raf = requestAnimationFrame(frame); // start up again when its appearing
	}
});

if (reduced) {
	gl.uniform1f(u.time, 0); // Stop Timer
	gl.drawArrays(gl.TRIANGLES, 0, 3); // Draw Last Frame
} else {
	raf = requestAnimationFrame(frame); // We back
}

// 7. reloadPalette()    -> cache-busted <link> swap, then uploadPalette
function reloadPalette(gl, u) {
	const old  = document.getElementById('palette');
	const link = document.createElement('link');
	link.rel  = 'stylesheet';
	link.id   = 'palette';
	link.href = 'colors.css?t=' + Date.now();
	link.onload = () => {
		old.remove();
		uploadPalette(gl, u);
		gl.drawArrays(gl.TRIANGLES, 0,3);
	};
	document.head.appendChild(link);
}

setInterval(() => reloadPalette(gl, u), 500);
