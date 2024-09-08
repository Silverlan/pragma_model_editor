#version 440

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

#define DEBUG_MODE DEBUG_MODE_NONE

#include "/common/pixel_outputs/fs_bloom_color.glsl"
#include "/programs/scene/scene_push_constants.glsl"
#include "/programs/scene/pbr/fs_core.glsl"

void main()
{
	vec2 uv = get_uv_coordinates();
	vec4 albedoColor = texture(u_albedoMap,uv);
	fs_color = calc_pbr(albedoColor,uv,u_pushConstants.debugMode);
	if(CSPEC_BLOOM_OUTPUT_ENABLED == 1)
		extract_bright_color(fs_color);
}