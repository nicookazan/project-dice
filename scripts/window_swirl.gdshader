shader_type canvas_item;
// TX2: ondas de giro que viajan hacia el centro (galaxia y agujero negro). Solo presentación.
// Cada píxel toma el color de otro punto del mismo panel, girado un ángulo que oscila con el radio y el tiempo:
// no hay rotación acumulada, así que el remolino nunca se deshace ni se reinicia.
uniform vec2 center = vec2(200.0, 55.0);
uniform float tilt = 0.0;
uniform float ratio = 0.4;
uniform float rmax = 100.0;
uniform float omega = 1.0;
uniform float amp = 0.3;
uniform float k = 0.07;
uniform float t = 0.0;
uniform vec2 tex_size = vec2(402.0, 111.0);

void fragment() {
	vec2 p = floor(UV * tex_size);
	vec2 d = p - center;
	float ct = cos(tilt);
	float st = sin(tilt);
	float u = d.x * ct + d.y * st;
	float v = (-d.x * st + d.y * ct) / ratio;
	float r = length(vec2(u, v));
	vec2 src = p;
	if (r < rmax && r >= 2.0) {
		float q = clamp((r / rmax - 0.68) / 0.32, 0.0, 1.0);
		float fade = 1.0 - q * q * (3.0 - 2.0 * q);
		float ang = atan(v, u) - fade * amp * sin(r * k - omega * t);
		float u2 = r * cos(ang);
		float v2 = r * sin(ang) * ratio;
		src = floor(center + vec2(u2 * ct - v2 * st, u2 * st + v2 * ct) + 0.5);
	}
	src = clamp(src, vec2(0.0), tex_size - 1.0);
	COLOR = texture(TEXTURE, (src + 0.5) / tex_size);
}
