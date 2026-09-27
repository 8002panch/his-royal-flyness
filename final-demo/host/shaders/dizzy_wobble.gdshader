shader_type canvas_item;

// Dizziness on the main screen (docs/GAME.md: a wrong answer makes Hamlet wobbly): the court behind the HUD swirls around
// the middle and ripples in slow waves, with a faint colour split. strength 0 = untouched, 1 = extremely wobbly.
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float strength = 0.0;
uniform float aspect = 1.7778;

void fragment() {
	vec2 uv = SCREEN_UV;
	float s = strength;
	// the swirl: a twist around the centre that breathes back and forth, strongest in the middle
	vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
	float r = length(p);
	float ang = s * 1.1 * sin(TIME * 0.7) * exp(-r * 1.8);
	p = mat2(vec2(cos(ang), sin(ang)), vec2(-sin(ang), cos(ang))) * p;
	uv = p / vec2(aspect, 1.0) + 0.5;
	// the waves: slow ripples across and down the screen
	uv.x += s * 0.014 * sin(uv.y * 17.0 + TIME * 2.6);
	uv.y += s * 0.010 * sin(uv.x * 13.0 + TIME * 2.1);
	// a faint double vision
	vec2 split = vec2(s * 0.004 * sin(TIME * 1.3), 0.0);
	float red = texture(screen_tex, uv + split).r;
	vec2 gb = texture(screen_tex, uv).gb;
	float blue = texture(screen_tex, uv - split).b;
	COLOR = vec4(red, gb.x, blue, 1.0);
}
