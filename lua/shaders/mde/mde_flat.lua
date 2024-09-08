util.register_class("shader.MdeFlat", shader.BaseGraphics)

local SHADER_UNIFORM_BONE_MATRIX_SET = 0
local SHADER_UNIFORM_BONE_MATRIX_BINDING = 0

shader.MdeFlat.FragmentShader = "programs/mde/flat_vertex_color"
shader.MdeFlat.VertexShader = "programs/mde/flat_vertex_color"

function shader.MdeFlat:__init()
	shader.BaseGraphics.__init(self)
	self.m_dsMVP = util.DataStream(util.SIZEOF_MAT4)
end
function shader.MdeFlat:OnInitialized()
	local boneBuffer, instanceSize = ents.get_instance_bone_buffer()
	self.m_descSetBone = self:GetShader():CreateDescriptorSet(SHADER_UNIFORM_BONE_MATRIX_SET)
	self.m_descSetBone:SetBindingUniformBufferDynamic(SHADER_UNIFORM_BONE_MATRIX_BINDING, boneBuffer, 0, instanceSize)
end
function shader.MdeFlat:InitializeRenderPass(pipelineIdx)
	return { shader.Scene3D.get_render_pass() }
end
function shader.MdeFlat:InitializeShaderResources()
	shader.BaseGraphics.InitializeShaderResources(self)
	self:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX), {
		shader.VertexAttribute(prosper.FORMAT_R32G32B32_SFLOAT), -- Position
		shader.VertexAttribute(prosper.FORMAT_R32G32B32A32_SFLOAT), -- Color
	})
	self:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX), {
		shader.VertexAttribute(prosper.FORMAT_R32_SINT), -- Bone Ids
	})
	self:AttachDescriptorSetInfo(shader.DescriptorSetInfo("BONES", {
		shader.DescriptorSetBinding(
			"MATRIX_DATA",
			prosper.DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC,
			prosper.SHADER_STAGE_VERTEX_BIT
		),
	}))
	self:AttachPushConstantRange(0, util.SIZEOF_MAT4, prosper.SHADER_STAGE_VERTEX_BIT)
end
function shader.MdeFlat:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self, pipelineInfo, pipelineIdx)
	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_FILL)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
	pipelineInfo:SetDepthTestEnabled(true)
	pipelineInfo:SetDepthWritesEnabled(true)
	pipelineInfo:SetCommonAlphaBlendProperties()
end
function shader.MdeFlat:CreateBuffers(ent, color)
	local mdlComponent = ent:GetComponent(ents.COMPONENT_MODEL)
	if mdlComponent == nil then
		return
	end
	local mdl = mdlComponent:GetModel()
	if util.is_valid(mdl) == false then
		return
	end
	color = color or Color.Red
	local vColor = color:ToVector4()
	local skeleton = mdl:GetSkeleton()
	local refPose = mdl:GetReferencePose()

	local offsets = {}
	local dsVerts = util.DataStream()
	local dsIndices = util.DataStream()
	local function add_bones(boneParent, offsets)
		local parentId = boneParent:GetID()
		local posParent = refPose:GetBoneTransform(parentId)
		for boneId, bone in pairs(boneParent:GetChildren()) do
			add_bones(bone, offsets)

			local pos = refPose:GetBoneTransform(boneId)
			offsets[boneId] = dsVerts:Tell()
			-- Vertices and colors
			dsVerts:WriteVector(posParent)
			dsVerts:WriteVector4(vColor)
			dsVerts:WriteVector(pos)
			dsVerts:WriteVector4(vColor)

			-- Bone Ids
			dsIndices:WriteUInt32(parentId)
			dsIndices:WriteUInt32(boneId)
		end
	end
	for boneId, bone in pairs(skeleton:GetRootBones()) do
		add_bones(bone, offsets)
	end

	local bufCreateInfo = prosper.BufferCreateInfo()
	bufCreateInfo.size = dsVerts:GetSize()
	bufCreateInfo.usageFlags = prosper.BUFFER_USAGE_VERTEX_BUFFER_BIT
	bufCreateInfo.memoryFeatures = prosper.MEMORY_FEATURE_GPU_BULK_BIT
	local bufVerts = prosper.create_buffer(bufCreateInfo, dsVerts)
	if bufVerts == nil then
		return
	end
	bufVerts:SetDebugName("mdlviewer_shader_flat_verts")
	local bufIndices = prosper.create_buffer(bufCreateInfo, dsIndices)
	if bufIndices == nil then
		return
	end
	bufIndices:SetDebugName("mdlviewer_shader_flat_indices")
	return bufVerts, bufIndices, offsets
end
function shader.MdeFlat:OnPrepareDraw(drawCmd) end
function shader.MdeFlat:Draw(drawCmd, ent, vertexBuffer, boneIndexBuffer, mvp, vertCount, firstVertex)
	local baseShader = self:GetShader()
	if baseShader:IsValid() == false then
		return
	end
	local bindState = shader.BindState(drawCmd)
	if baseShader:RecordBeginDraw(bindState) == false then
		return
	end
	local renderComponent = ent:GetComponent(ents.COMPONENT_RENDER)
	local boneBuffer = (renderComponent ~= nil) and renderComponent:GetBoneBuffer() or nil
	if util.is_valid(boneBuffer) == false then
		return
	end
	vertCount = vertCount or vertexBuffer:GetSize() / (util.SIZEOF_VECTOR3 + util.SIZEOF_VECTOR4)

	baseShader:RecordBindVertexBuffers(bindState, { vertexBuffer, boneIndexBuffer })
	baseShader:OnPrepareDraw(drawCmd)
	self.m_dsMVP:Seek(0)
	self.m_dsMVP:WriteMat4(mvp)
	baseShader:RecordPushConstants(bindState, self.m_dsMVP)
	baseShader:RecordBindDescriptorSet(
		bindState,
		self.m_descSetBone,
		SHADER_UNIFORM_BONE_MATRIX_SET,
		{ boneBuffer:GetStartOffset() }
	)
	baseShader:RecordDraw(bindState, vertCount, 1, firstVertex or 0)
	baseShader:RecordEndDraw(bindState)
end
shader.register("mde_flat", shader.MdeFlat)
