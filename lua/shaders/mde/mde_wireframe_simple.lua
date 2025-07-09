-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("shader.MdeWireframeSimple", shader.BaseGraphics)

local SHADER_VERTEX_COLOR_BUFFER_BINDING = 0

local SHADER_VERTEX_BUFFER_LOCATION = 0
local SHADER_VERTEX_BUFFER_BINDING = 0

local SHADER_COLOR_BUFFER_LOCATION = 1
local SHADER_COLOR_BUFFER_BINDING = 0

shader.MdeWireframeSimple.FragmentShader = "programs/mde/wireframe_simple"
shader.MdeWireframeSimple.VertexShader = "programs/mde/wireframe_simple"
function shader.MdeWireframeSimple:__init()
	shader.BaseGraphics.__init(self)
	self.m_dsMVP = util.DataStream(util.SIZEOF_MAT4)
end
function shader.MdeWireframeSimple:InitializeShaderResources()
	shader.BaseGraphics.InitializeShaderResources(self)
	self:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX), {
		shader.VertexAttribute(prosper.FORMAT_R32G32B32_SFLOAT), -- Position
		shader.VertexAttribute(prosper.FORMAT_R32G32B32A32_SFLOAT), -- Color
	})
	self:AttachPushConstantRange(0, util.SIZEOF_MAT4, prosper.SHADER_STAGE_VERTEX_BIT)
end
function shader.MdeWireframeSimple:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self, pipelineInfo, pipelineIdx)

	pipelineInfo:SetDepthTestEnabled(true)
	pipelineInfo:SetDepthWritesEnabled(true)
	pipelineInfo:SetDynamicStateEnabled(prosper.DYNAMIC_STATE_LINE_WIDTH_BIT, true)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_LINE_LIST)
	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_LINE)
end
function shader.MdeWireframeSimple:InitializeRenderPass(pipelineIdx)
	return { shader.Scene3D.get_render_pass() }
end
function shader.MdeWireframeSimple:Draw(vertexBuffer, mvp)
	if self:IsValid() == false then
		return
	end
	local bindState = shader.BindState(drawCmd)
	if self:RecordBeginDraw(bindState) == false then
		return
	end
	local vertCount = vertexBuffer:GetSize() / (util.SIZEOF_VECTOR3 + util.SIZEOF_VECTOR4)
	self:RecordBindVertexBuffer(bindState, vertexBuffer, SHADER_VERTEX_COLOR_BUFFER_BINDING)
	drawCmd:RecordSetLineWidth(bindState, 2.0)

	self.m_dsMVP:Seek(0)
	self.m_dsMVP:WriteMat4(mvp)
	self:RecordPushConstants(bindState, self.m_dsMVP)

	drawCmd:RecordDraw(bindState, vertCount)

	self:RecordEndDraw(bindState)
end
shader.register("mde_wireframe_simple", shader.MdeWireframeSimple)
