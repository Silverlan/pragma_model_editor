-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("mde_skeleton.lua")
util.register_class("shader.MdeSkeletonDepth", shader.MdeSkeleton)

function shader.MdeSkeletonDepth:__init()
	shader.MdeSkeleton.__init(self)
end
function shader.MdeSkeletonDepth:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.MdeSkeleton.InitializePipeline(self, pipelineInfo, pipelineIdx)
	pipelineInfo:SetDepthTestEnabled(true)
	pipelineInfo:SetDepthWritesEnabled(true)
end
shader.register("mde_skeleton_depth", shader.MdeSkeletonDepth)
