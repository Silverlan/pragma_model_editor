#version 440

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

#define SHADER_VERTEX_BUFFER_LOCATION 0
#define SHADER_COLOR_BUFFER_LOCATION 1
#define SHADER_BONE_INDEX_BUFFER_LOCATION 2

#include "/common/limits.glsl"
#include "flat.glsl"

layout(std140,LAYOUT_ID(BONES,MATRIX_DATA)) uniform Bones
{
	mat4 matrices[MAX_BONES];
} u_bones;

layout(location = SHADER_VERTEX_BUFFER_LOCATION) in vec3 in_vert_pos;
layout(location = SHADER_COLOR_BUFFER_LOCATION) in vec4 in_vert_color;
layout(location = SHADER_BONE_INDEX_BUFFER_LOCATION) in int in_vert_bone;

layout(LAYOUT_PUSH_CONSTANTS()) uniform Matrices {
	mat4 MVP;
} u_matrices;

void main()
{
	vec4 pos = vec4(in_vert_pos,1.0);
	if(in_vert_bone >= 0)
		pos = u_bones.matrices[in_vert_bone] *pos;
	gl_Position = u_matrices.MVP *pos;
	vs_out.frag_col = in_vert_color;
}