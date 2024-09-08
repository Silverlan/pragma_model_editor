#version 440

// This shader is obsolete?

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

#include "../modules/vs_world.gls"

void main()
{
	gl_PointSize = 4.0;
	export_world_fragment_data();
}
