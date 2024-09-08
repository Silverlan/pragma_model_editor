#version 440

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

#include "vertex_weights.glsl"
#include "/common/pixel_outputs/fs_bloom_color.glsl"
#include "/programs/scene/scene_push_constants.glsl"

void main()
{
	fs_color = vec4(u_pushConstants.fragColorR,u_pushConstants.fragColorG,u_pushConstants.fragColorB,u_pushConstants.fragColorA *fs_weight_alpha_in.alpha);
}