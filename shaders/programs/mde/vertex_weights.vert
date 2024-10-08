#version 440

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

#include "vertex_weights.glsl"
#include "/programs/scene/vs_world.glsl"

void main()
{
	export_world_fragment_data(false, false);
	vs_weight_alpha_out.alpha = 0.0;
	for(int i=0;i<4;i++)
	{
		if(in_boneWeightIDs[i] == u_pushConstants.boneId)
		{
			vs_weight_alpha_out.alpha = in_weights[i];
			break;
		}
	}
	// TODO: Extended weights?
}
