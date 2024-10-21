#version 440

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

#define SHADER_VERTEX_BUFFER_LOCATION 0
#define SHADER_VERTEX_COLOR_LOCATION 1

#include "wireframe_simple.glsl"

layout(location = SHADER_VERTEX_BUFFER_LOCATION) in vec3 in_vert_pos;
layout(location = SHADER_VERTEX_COLOR_LOCATION) in vec3 in_vert_col;

layout(LAYOUT_PUSH_CONSTANTS()) uniform Matrices {
	mat4 MVP;
} u_matrices;

void main()
{
	gl_Position = u_matrices.MVP *vec4(in_vert_pos,1);
	vs_out.frag_col = vec4(in_vert_col,1.0);
}