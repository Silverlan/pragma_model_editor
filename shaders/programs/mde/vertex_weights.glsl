#ifndef F_SH_MDE_VERTEX_WEIGHTS_GLS
#define F_SH_MDE_VERTEX_WEIGHTS_GLS

#define PUSH_USER_CONSTANTS \
	float fragColorR; \
	float fragColorG; \
	float fragColorB; \
	float fragColorA; \
	int boneId;

#include "/common/vertex_data_locations.glsl"
#include "/common/export.glsl"

#define SHADER_WEIGHT_ALPHA_LOCATION SHADER_USER1_LOCATION

layout(location = SHADER_WEIGHT_ALPHA_LOCATION) EXPORT_VS VS_WEIGHT_ALPHA_OUT
{
	float alpha;
}
#ifdef GLS_FRAGMENT_SHADER
	fs_weight_alpha_in
#else
	vs_weight_alpha_out
#endif
;

#endif
