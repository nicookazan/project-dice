shader_type canvas_item;
render_mode unshaded;

uniform int body_kind = 0;
uniform vec4 pip_boxes[6];
uniform int pip_count = 0;
varying vec2 face_position;

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
			result = mix(vec3(0.07, 0.09, 0.12), vec3(0.93, 0.96, 1.0), shade);
		} else {
			result = mix(vec3(0.19, 0.055, 0.025), vec3(1.0, 0.59, 0.23), shade);
			if (shade > 0.91) result = mix(result, vec3(1.0, 0.90, 0.69), (shade - 0.91) / 0.09);
		}
	}
	COLOR = vec4(result, source.a);
}
