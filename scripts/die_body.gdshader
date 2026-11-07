shader_type canvas_item;
render_mode unshaded;

uniform int body_kind = 0;
uniform vec4 pip_boxes[6];
uniform int pip_count = 0;
uniform sampler2D body_mask : filter_nearest, repeat_disable;
uniform vec2 mask_origin = vec2(3.0, 2.0);
varying vec2 face_position;

// Rampas de los metales nuevos (D16). Las máscaras viven en metales-mascaras-v3.png (generador: tools/art/make_metales.py).
const vec3 RUST[6] = vec3[6](vec3(0.173, 0.067, 0.039), vec3(0.333, 0.133, 0.059), vec3(0.510, 0.208, 0.102), vec3(0.690, 0.310, 0.133), vec3(0.851, 0.478, 0.173), vec3(0.941, 0.651, 0.290));
const vec3 GREEN[6] = vec3[6](vec3(0.043, 0.149, 0.133), vec3(0.078, 0.275, 0.235), vec3(0.122, 0.420, 0.341), vec3(0.188, 0.627, 0.486), vec3(0.400, 0.796, 0.639), vec3(0.706, 0.945, 0.816));
const vec3 GOLD[6] = vec3[6](vec3(0.247, 0.149, 0.020), vec3(0.490, 0.310, 0.055), vec3(0.749, 0.518, 0.098), vec3(0.937, 0.714, 0.173), vec3(1.000, 0.859, 0.345), vec3(1.000, 0.965, 0.722));

vec3 steel_color(float shade) {
	return mix(vec3(0.07, 0.09, 0.12), vec3(0.93, 0.96, 1.0), shade);
}

vec3 copper_color(float shade) {
	vec3 result = mix(vec3(0.19, 0.055, 0.025), vec3(1.0, 0.59, 0.23), shade);
	if (shade > 0.91) result = mix(result, vec3(1.0, 0.90, 0.69), (shade - 0.91) / 0.09);
	return result;
}

vec4 mask_at(float cell) {
	vec2 point = (face_position + mask_origin) / 62.0;
	return texture(body_mask, vec2((clamp(point.x, 0.0, 1.0) + cell) * 0.5, clamp(point.y, 0.0, 1.0)));
}

vec3 ramp_color(int which, float index) {
	int i = int(clamp(floor(index), 0.0, 5.0));
	if (which == 0) return RUST[i];
	if (which == 1) return GREEN[i];
	return GOLD[i];
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
		// Fine horizontal blocks follow the source shading, keeping its bevels.
		float grain = (mod(floor(face_position.y * 3.0), 3.0) - 1.0) * 0.016;
		float shade = clamp(lightness * 1.06 - 0.06 + grain, 0.0, 1.0);
		if (body_kind == 1) {
			result = steel_color(shade);
		} else if (body_kind == 2) {
			result = copper_color(shade);
		} else if (body_kind == 3) {
			// Hierro oxidado: costra y goteos fijos sobre el acero.
			vec4 m = mask_at(0.0);
			if (m.r > 0.5) {
				float tone = shade * 0.55 + (m.g - 0.5);
				result = m.b > 0.5 ? RUST[0] : ramp_color(0, tone * 5.2 + 1.0);
			} else {
				result = steel_color(shade) * 0.92;
			}
		} else if (body_kind == 4) {
			// Cobre oxidado: pátina en manchas, el cobre asoma en los bordes.
			vec4 m = mask_at(1.0);
			if (m.r > 0.5) {
				float tone = shade * 0.6 + (m.g - 0.5);
				result = ramp_color(1, tone * 5.4 + 0.8);
			} else {
				result = copper_color(shade);
			}
		} else {
			// Oro pulido: rampa por brillo y una franja de reflejo en diagonal.
			float index = pow(clamp((shade - 0.5) / 0.42, 0.0, 1.0), 1.7) * 5.6;
			vec2 at = face_position + mask_origin;
			if (abs(at.x + at.y - 52.0) < 3.0) index = min(index + 1.6, 5.0);
			result = ramp_color(2, index);
		}
	}
	COLOR = vec4(result, source.a);
}
