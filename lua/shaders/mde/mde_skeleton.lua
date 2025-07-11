-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("mde_flat.lua")
util.register_class("shader.MdeSkeleton", shader.MdeFlat)
shader.MdeSkeleton.FragmentShader = "programs/mde/skeleton"
function shader.MdeSkeleton:__init()
	shader.MdeFlat.__init(self)
end
function shader.MdeSkeleton:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.MdeFlat.InitializePipeline(self, pipelineInfo, pipelineIdx)
	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_LINE)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_LINE_LIST)
	pipelineInfo:SetDynamicStateEnabled(prosper.DYNAMIC_STATE_LINE_WIDTH_BIT, true)
	pipelineInfo:SetDepthTestEnabled(false)
	pipelineInfo:SetDepthWritesEnabled(false)
end
function shader.MdeSkeleton:OnPrepareDraw(drawCmd)
	shader.MdeFlat.OnPrepareDraw(self, drawCmd)
	drawCmd:RecordSetLineWidth(2.0)
end
shader.register("mde_skeleton", shader.MdeSkeleton)
