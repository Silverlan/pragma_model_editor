include("mde_textured.lua")

util.register_class("shader.MdeVertexWeights",shader.MdeTextured)

shader.MdeVertexWeights.FragmentShader = "mde/fs_mde_vertex_weights"
shader.MdeVertexWeights.VertexShader = "mde/vs_mde_vertex_weights"
shader.MdeVertexWeights.MESH_COLOR = Color.Magenta:ToVector4()
shader.MdeVertexWeights.SetMeshColor = function(color)
	shader.MdeVertexWeights.MESH_COLOR = color:ToVector4()
end
function shader.MdeVertexWeights:__init()
	shader.MdeTextured.__init(self)

	self.m_dsBone = util.DataStream(util.SIZEOF_VECTOR4 +util.SIZEOF_INT)
end
function shader.MdeVertexWeights:InitializeGfxPipelinePushConstantRanges(pipelineInfo,pipelineIdx)
	pipelineInfo:AttachPushConstantRange(
		0,shader.TexturedLit3D.PUSH_CONSTANTS_SIZE +self.m_dsBone:GetSize(),
		bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_VERTEX_BIT)
	) -- Color and Bone Id
end
function shader.MdeVertexWeights:OnDraw(mesh)
	if(self.m_drawing) then return end
	self.m_drawing = true
	local ent = self:GetBoundEntity()
	local mdeC = (ent ~= nil) and ent:GetComponent(ents.COMPONENT_MDE_MODEL_PREVIEW) or nil
	if(mdeC == nil) then return util.EVENT_REPLY_HANDLED end
	self.m_dsBone:Seek(0)
	self.m_dsBone:WriteVector4(shader.MdeVertexWeights.MESH_COLOR)
	for boneId,b in pairs(mdeC:GetSelectedBones()) do
		self.m_dsBone:Seek(util.SIZEOF_VECTOR4)
		self.m_dsBone:WriteUInt32(boneId)
		if(self:RecordPushConstants(self.m_dsBone,shader.TexturedLit3D.PUSH_CONSTANTS_USER_DATA_OFFSET)) then self:RecordDrawMesh(mesh) end
	end
	self.m_drawing = false
	return util.EVENT_REPLY_HANDLED
end
shader.register("mde_vertex_weights",shader.MdeVertexWeights)
