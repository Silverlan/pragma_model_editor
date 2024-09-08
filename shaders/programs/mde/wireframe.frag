#version 440

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

#include "wireframe.glsl"
#include "/common/pixel_outputs/fs_bloom_color.glsl"
#include "/programs/scene/scene_push_constants.glsl"

void main()
{
	fs_color = u_pushConstants.wireframeColor;
	extract_bright_color(fs_color);
}