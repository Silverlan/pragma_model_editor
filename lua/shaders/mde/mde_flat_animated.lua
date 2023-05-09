include("mde_textured.lua")

util.register_class("shader.MdeFlatAnimated", shader.MdeTextured)

shader.MdeFlatAnimated.FragmentShader = "mde/fs_mde_flat"
function shader.MdeFlatAnimated:__init()
	shader.MdeTextured.__init(self)
end
function shader.MdeFlatAnimated:InitializeGfxPipelinePushConstantRanges(pipelineInfo, pipelineIdx)
	pipelineInfo:AttachPushConstantRange(
		0,
		shader.TexturedLit3D.PUSH_CONSTANTS_SIZE + util.SIZEOF_VECTOR4,
		bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT, prosper.SHADER_STAGE_VERTEX_BIT)
	) -- Color
end
function shader.MdeFlatAnimated:OnBindScene(renderer, view)
	local hullColor = Color.LawnGreen:Copy()
	hullColor.a = 128

	local dsColor = util.DataStream()
	dsColor:WriteVector4(hullColor:ToVector4())

	self:RecordPushConstants(dsColor, shader.TexturedLit3D.PUSH_CONSTANTS_USER_DATA_OFFSET)
end
shader.register("mde_flat_animated", shader.MdeFlatAnimated)
