extends TextureRect

# Shader-based background motion used by menu/codex/settings screens.
# The image stays the same, but slow UV drift and glow pulses make it feel
# alive without requiring extra animated assets.

@export var drift_strength: float = 0.024
@export var glow_strength: float = 0.46
@export var dim_strength: float = 0.34


func _ready() -> void:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float drift_strength = 0.024;
uniform float glow_strength = 0.46;
uniform float dim_strength = 0.34;

void fragment() {
	float t = TIME;
	vec2 slow_drift = vec2(sin(t * 0.055) * drift_strength + t * 0.0022, cos(t * 0.047) * drift_strength * 0.70);
	vec2 cross_drift = vec2(cos(t * 0.038) * drift_strength * 0.62, sin(t * 0.052) * drift_strength * 0.82);
	vec2 uv_a = fract(UV + slow_drift);
	vec2 uv_b = fract((UV - vec2(0.5)) * 1.045 + vec2(0.5) - cross_drift);
	vec4 base = texture(TEXTURE, uv_a);
	vec4 haze = texture(TEXTURE, uv_b);
	float wave = sin(UV.x * 8.0 + UV.y * 5.0 + t * 0.78) * 0.5 + 0.5;
	float pulse = sin(t * 0.58) * 0.5 + 0.5;
	float ember = sin(UV.x * 18.0 - UV.y * 11.0 + t * 0.45) * 0.5 + 0.5;
	float vignette = 1.0 - smoothstep(0.18, 0.86, distance(UV, vec2(0.5)));
	vec3 color = mix(base.rgb, haze.rgb, 0.24);
	color += vec3(0.02, 0.34, 0.42) * wave * glow_strength * vignette;
	color += vec3(0.24, 0.10, 0.03) * ember * glow_strength * 0.34;
	color *= 1.0 - dim_strength * (1.0 - wave) * (0.46 + pulse * 0.34);
	color += vec3(0.02, 0.08, 0.10) * pulse * glow_strength * 0.16;
	COLOR = vec4(color, base.a);
}
"""

	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var shader_material: ShaderMaterial = ShaderMaterial.new()
	shader_material.shader = shader
	shader_material.set_shader_parameter("drift_strength", drift_strength)
	shader_material.set_shader_parameter("glow_strength", glow_strength)
	shader_material.set_shader_parameter("dim_strength", dim_strength)
	material = shader_material
