#version 440

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

#include "wireframe.glsl"
#include "/programs/scene/vs_world.glsl"

void main()
{
	export_world_fragment_data(false, false);

	gl_PointSize = 4.0;
}
