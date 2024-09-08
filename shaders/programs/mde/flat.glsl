#ifndef F_SH_MDE_SKELETON_GLS
#define F_SH_MDE_SKELETON_GLS

#include "/common/export.glsl"

#define SHADER_VERTEX_DATA_LOCATION 0

layout(location = SHADER_VERTEX_DATA_LOCATION) EXPORT_VS VS_OUT
{
	vec4 frag_col;
}
#ifdef GLS_FRAGMENT_SHADER
	fs_in
#else
	vs_out
#endif
;

#endif
