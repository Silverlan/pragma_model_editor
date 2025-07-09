-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

class("WIModelEditorWireframeMesh")
function WIModelEditorWireframeMesh:__init(verts, colors)
	self.m_bValid = false
	if #verts ~= #colors then
		return
	end
	local shaderWireframe = shader.get("mde_wireframe_simple")
	if shaderWireframe == nil then
		return
	end
	self.m_shader = shaderWireframe

	local dsVerts = util.DataStream(util.SIZEOF_VECTOR3 * #verts * 2)
	for i = 1, #verts do
		dsVerts:WriteVector(verts[i])
		dsVerts:WriteVector4(colors[i]:ToVector4())
	end
	local bufCreateInfo = prosper.BufferCreateInfo()
	bufCreateInfo.size = dsVerts:GetSize()
	bufCreateInfo.usageFlags = prosper.BUFFER_USAGE_VERTEX_BUFFER_BIT
	bufCreateInfo.memoryFeatures = prosper.MEMORY_FEATURE_GPU_BULK_BIT
	local bufVert = prosper.create_buffer(bufCreateInfo, dsVerts)
	if bufVert == nil then
		return
	end
	bufVert:SetDebugName("mdlviewer_wireframe_mesh_verts")
	self.m_bufVerts = bufVert
	self.m_vertexCount = #verts
	self.m_modelMatrix = Mat4(1.0)
	self.m_bValid = true
end
function WIModelEditorWireframeMesh:IsValid()
	return self.m_bValid
end
function WIModelEditorWireframeMesh:Draw(rt, m)
	if self:IsValid() == false or self.m_shader == nil then
		return
	end
	self.m_shader:Draw(self.m_bufVerts, m or self.m_modelMatrix, self.m_vertexCount)
end
