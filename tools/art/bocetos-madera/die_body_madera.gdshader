shader_type canvas_item;
render_mode unshaded;
// BOCETO de la madera (no integrado): cuatro diseños para elegir. Se usa desde tools/art/bocetos-madera/madera_review.gd.
uniform int body_kind = 0;
uniform int design = 1;
uniform vec4 pip_boxes[6];
uniform int pip_count = 0;
uniform vec2 mask_origin = vec2(3.0, 2.0);
varying vec2 face_position;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 pick(vec3 ramp[5], float index) {
	return ramp[int(clamp(floor(index), 0.0, 4.0))];
}

void vertex() {
	face_position = VERTEX;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	bool pip = false;
	for (int i = 0; i < 6; i++) {
		if (i < pip_count) {
			vec4 box = pip_boxes[i];
			pip = pip || (face_position.x >= box.x && face_position.y >= box.y && face_position.x <= box.z && face_position.y <= box.w);
		}
	}
	vec3 result = source.rgb;
	if (body_kind > 0 && !pip) {
		float lightness = dot(source.rgb, vec3(0.299, 0.587, 0.114));
		float shade = clamp(lightness * 1.06 - 0.06, 0.0, 1.0);
		vec2 at = floor(face_position + mask_origin);
		float tone = shade * 3.2 + 0.4;
		if (design == 1) {
			// A · Roble claro: vetas horizontales onduladas y un nudo.
			vec3 ramp[5] = vec3[5](vec3(0.33, 0.19, 0.09), vec3(0.53, 0.33, 0.16), vec3(0.72, 0.49, 0.25), vec3(0.85, 0.65, 0.38), vec3(0.95, 0.80, 0.55));
			float wave = sin(at.x * 0.18 + sin(at.y * 0.4) * 1.2) * 2.2;
			float vein = sin((at.y + wave) * 0.95);
			float grain = vein > 0.72 ? -1.0 : (vein < -0.8 ? 0.5 : 0.0);
			vec2 k = at - vec2(38.0, 20.0);
			float knot = length(vec2(k.x * 0.6, k.y));
			if (knot < 7.0) grain += (mod(floor(knot * 0.7), 2.0) < 1.0) ? -1.0 : -0.4;
			if (hash(at) > 0.93) grain -= 0.5;
			result = pick(ramp, tone + grain);
		} else if (design == 2) {
			// B · Nogal oscuro: fibras verticales finas, poro y brillo en el borde.
			vec3 ramp[5] = vec3[5](vec3(0.12, 0.06, 0.04), vec3(0.24, 0.12, 0.07), vec3(0.37, 0.20, 0.11), vec3(0.50, 0.29, 0.16), vec3(0.66, 0.42, 0.25));
			float fiber = hash(vec2(at.x, floor(at.y / 9.0)));
			float grain = fiber > 0.78 ? -1.0 : (fiber < 0.18 ? 0.8 : 0.0);
			if (hash(at + 7.0) > 0.965) grain -= 1.0;
			result = pick(ramp, tone + grain - 0.2);
		} else if (design == 3) {
			// C · Tablones: tres tablas con junta oscura, vetas propias y dos clavos.
			vec3 ramp[5] = vec3[5](vec3(0.20, 0.10, 0.05), vec3(0.38, 0.21, 0.10), vec3(0.56, 0.33, 0.16), vec3(0.73, 0.47, 0.24), vec3(0.88, 0.63, 0.36));
			float plank = floor((at.x - 2.0) / 17.0);
			float local = mod(at.x - 2.0, 17.0);
			float offset = hash(vec2(plank, 3.0)) * 0.9 - 0.3;
			float vein = sin((at.x * 1.7 + plank * 5.0) + sin(at.y * 0.25 + plank) * 1.4);
			float grain = vein > 0.8 ? -0.9 : 0.0;
			float t = tone + offset + grain;
			if (local < 1.0) t = 0.2;
			vec2 nail = vec2(local - 8.0, 0.0);
			if (abs(nail.x) < 1.0 && (abs(at.y - 7.0) < 1.0 || abs(at.y - 47.0) < 1.0)) t = 4.6;
			result = pick(ramp, t);
		} else {
			// D · Anillos: corte de tronco, anillos de crecimiento y una grieta radial.
			vec3 ramp[5] = vec3[5](vec3(0.26, 0.14, 0.07), vec3(0.45, 0.27, 0.13), vec3(0.65, 0.42, 0.21), vec3(0.82, 0.60, 0.34), vec3(0.93, 0.76, 0.50));
			vec2 c = at - vec2(30.0, 28.0);
			float radius = length(vec2(c.x * 1.0, c.y * 1.08));
			float ring = mod(floor(radius / 3.2), 2.0);
			float t = tone + (ring < 1.0 ? 0.0 : -0.9);
			if (mod(radius, 3.2) < 0.9) t -= 0.5;
			if (abs(c.y) < 0.7 && c.x > 4.0) t = 0.3;
			result = pick(ramp, t);
		}
	}
	COLOR = vec4(result, source.a);
}
