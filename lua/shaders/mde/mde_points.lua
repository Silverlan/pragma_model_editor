-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("shader.MdePoints", shader.BaseTexturedLit3D)

shader.MdePoints.FragmentShader = "programs/mde/wireframe"
shader.MdePoints.VertexShader = "programs/mde/wireframe"
shader.MdePoints.POINT_COLOR = Color.Red:ToVector4()
shader.MdePoints.SetPointColor = function(color)
	shader.MdePoints.POINT_COLOR = color:ToVector4()
end
function shader.MdePoints:__init()
	shader.BaseTexturedLit3D.__init(self)
	self.m_dsPushConstants = util.DataStream(util.SIZEOF_VECTOR4)
end
function shader.MdePoints:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self, pipelineInfo, pipelineIdx)

	pipelineInfo:SetDepthBiasEnabled(true)
	pipelineInfo:SetDepthBiasSlopeFactor(-0.001)
	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_POINT)
	pipelineInfo:SetDynamicStateEnabled(prosper.DYNAMIC_STATE_LINE_WIDTH_BIT, true)
	pipelineInfo:SetLineWidth(4)
end
function shader.MdePoints:InitializeGfxPipelinePushConstantRanges()
	self:AttachPushConstantRange(
		0,
		shader.TexturedLit3D.PUSH_CONSTANTS_SIZE + self.m_dsPushConstants:GetSize(),
		bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT, prosper.SHADER_STAGE_VERTEX_BIT)
	)
end
function shader.MdePoints:OnBindEntity(ent)
	local drawCmd = self:GetCurrentCommandBuffer()
	drawCmd:RecordSetLineWidth(4.0)

	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteVector4(shader.MdePoints.POINT_COLOR)
	self:RecordPushConstants(self.m_dsPushConstants, shader.TexturedLit3D.PUSH_CONSTANTS_USER_DATA_OFFSET)
end
shader.register("mde_points", shader.MdePoints)
