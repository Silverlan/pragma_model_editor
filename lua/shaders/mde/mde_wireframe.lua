-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("shader.MdeWireframe", shader.BaseTexturedLit3D)

shader.MdeWireframe.FragmentShader = "programs/mde/wireframe"
shader.MdeWireframe.VertexShader = "programs/mde/wireframe"
shader.MdeWireframe.WIREFRAME_COLOR = Color(255, 255, 128, 255):ToVector4()
shader.MdeWireframe.SetWireframeColor = function(color)
	shader.MdeWireframe.WIREFRAME_COLOR = color:ToVector4()
end
function shader.MdeWireframe:__init()
	shader.BaseTexturedLit3D.__init(self)
	self.m_dsPushConstants = util.DataStream(util.SIZEOF_VECTOR4)
end
function shader.MdeWireframe:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self, pipelineInfo, pipelineIdx)

	pipelineInfo:SetDepthBiasEnabled(true)
	pipelineInfo:SetDepthBiasSlopeFactor(-0.001)
	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_LINE)
	pipelineInfo:SetLineWidth(2)
end
function shader.MdeWireframe:InitializeGfxPipelinePushConstantRanges()
	self:AttachPushConstantRange(
		0,
		shader.TexturedLit3D.PUSH_CONSTANTS_SIZE + self.m_dsPushConstants:GetSize(),
		bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT, prosper.SHADER_STAGE_VERTEX_BIT)
	)
end
function shader.MdeWireframe:OnBindEntity(ent)
	local drawCmd = self:GetCurrentCommandBuffer()

	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteVector4(shader.MdeWireframe.WIREFRAME_COLOR)
	self:RecordPushConstants(self.m_dsPushConstants, shader.TexturedLit3D.PUSH_CONSTANTS_USER_DATA_OFFSET)
end
shader.register("mde_wireframe", shader.MdeWireframe)
