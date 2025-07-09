-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/pfm/treeview.lua")

util.register_class("gui.WIModelEditorMeshes", gui.Base, gui.WIModelEditorPanel)
local MARGIN_OFFSET = 20

function gui.WIModelEditorMeshes:__init()
	gui.Base.__init(self)
	gui.WIModelEditorPanel.__init(self)
end
function gui.WIModelEditorMeshes:OnInitialize()
	gui.Base.OnInitialize(self)

	local pMeshes = gui.create("WIPFMTreeView", self)
	pMeshes:SetAutoAlignToParent(true)
	pMeshes:SetX(MARGIN_OFFSET)
	-- pMeshes:SetScrollable(true)
	pMeshes:SetSelectable(gui.Table.SELECTABLE_MODE_SINGLE)
	self.m_pMeshes = pMeshes
end
function gui.WIModelEditorMeshes:PrepareRendering(pModelView)
	if self:GetShowItems() == false then
		return
	end
	pModelView:ScheduleEntityForRendering(nil, nil, function(ent, mdl, mesh, subMesh, mat)
		if self.m_selectedMesh ~= nil then
			return mesh == self.m_selectedMesh
		end
		if self.m_selectedSubMesh ~= nil then
			return subMesh == self.m_selectedSubMesh
		end
		return false
	end)
end
function gui.WIModelEditorMeshes:Render(drawCmd, cam)
	if self:GetShowItems() == false then
		return
	end
	local pEditor = self:GetEditor()
	local pModelView = pEditor:GetModelView()
	pModelView:RenderEntity(nil, function(ent, mdl, meshGroupId, meshGroup, mesh, subMesh, mat)
		-- if(self.m_selectedMeshGroup ~= nil and meshGroup ~= self.m_selectedMeshGroup) then return false end -- TODO
		if self.m_selectedMesh ~= nil and mesh ~= self.m_selectedMesh then
			return false
		end
		if self.m_selectedSubMesh ~= nil and subMesh ~= self.m_selectedSubMesh then
			return false
		end
		return true
	end, drawCmd)
end
function gui.WIModelEditorMeshes:SetSelected(b)
	gui.WIModelEditorPanel.SetSelected(self, b)
	local pEditor = self:GetEditor()
	if util.is_valid(pEditor) == false then
		return
	end
	self:GetEditor():ScheduleEntityForRendering()
	local pModelView = pEditor:GetModelView()
	pModelView:SetRenderFilterEnabled(not b)
	if b == true then
		pModelView:SetShowMeshes(false)
	else
		pEditor:UpdateShowMeshes()
	end
end
function gui.WIModelEditorMeshes:SetModel(mdl)
	local pMeshes = self.m_pMeshes
	if util.is_valid(pMeshes) == false then
		return
	end
	pMeshes:Clear()

	if util.is_valid(mdl) == false then
		return
	end
	local baseMeshIds = {}
	for _, id in ipairs(mdl:GetBaseMeshGroupIds()) do
		baseMeshIds[id] = true
	end
	for groupId, meshGroup in ipairs(mdl:GetMeshGroups()) do
		local name = meshGroup:GetName()
		if baseMeshIds[groupId - 1] == true then
			name = name .. " (Base mesh)"
		end
		local pEl = pMeshes:AddItem(name)
		pEl:AddCallback("OnSelected", function(pEl)
			self.m_selectedMeshGroup = meshGroup
		end)
		pEl:AddCallback("OnDeselected", function(pEl)
			self.m_selectedMeshGroup = nil
		end)
		local meshes = meshGroup:GetMeshes()
		for meshId, mesh in ipairs(meshes) do
			local pElMesh = pEl:AddItem(
				"Mesh #"
					.. meshId
					.. " ("
					.. mesh:GetVertexCount()
					.. " vertices) ("
					.. mesh:GetTriangleCount()
					.. " triangles)"
			)
			pElMesh:AddCallback("OnSelected", function(pEl)
				self.m_selectedMesh = mesh
			end)
			pElMesh:AddCallback("OnDeselected", function(pEl)
				self.m_selectedMesh = nil
			end)
			for subMeshId, subMesh in ipairs(mesh:GetSubMeshes()) do
				local pElSubMesh = pElMesh:AddItem(
					"SubMesh #"
						.. subMeshId
						.. " ("
						.. subMesh:GetVertexCount()
						.. " vertices) ("
						.. subMesh:GetTriangleCount()
						.. " triangles)"
				)
				pElSubMesh:AddCallback("OnMouseEvent", function(pElSubMesh, button, state, mods)
					if button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS then
						local isDistinct = true
						local skinTexId = subMesh:GetSkinTextureIndex()
						for groupId, meshGroup in ipairs(mdl:GetMeshGroups()) do
							for meshId, mesh in ipairs(meshGroup:GetMeshes()) do
								for subMeshId, subMeshOther in ipairs(mesh:GetSubMeshes()) do
									if
										util.is_same_object(subMesh, subMeshOther) == false
										and skinTexId == subMeshOther:GetSkinTextureIndex()
									then
										isDistinct = false
										break
									end
								end
								if isDistinct == false then
									break
								end
							end
							if isDistinct == false then
								break
							end
						end
						if isDistinct == true then
							return util.EVENT_REPLY_UNHANDLED
						end

						local pContext = gui.open_context_menu()
						if util.is_valid(pContext) == false then
							return
						end
						pContext:SetPos(input.get_cursor_pos())
						pContext:AddItem(locale.get_text("mde_assign_distinct_material"), function()
							local matIdx = mdl:AssignDistinctMaterial(meshGroup, mesh, subMesh)
						end)
						pContext:Update()
						return util.EVENT_REPLY_HANDLED
					end
					return util.EVENT_REPLY_UNHANDLED
				end)
				pElSubMesh:AddCallback("OnSelected", function(pEl)
					self.m_selectedSubMesh = subMesh
				end)
				pElSubMesh:AddCallback("OnDeselected", function(pEl)
					self.m_selectedSubMesh = nil
				end)
			end
		end
	end
	pMeshes:ExpandAll()
end
function gui.WIModelEditorMeshes:OnSizeChanged(w, h)
	gui.Base.OnSizeChanged(self, w, h)
end
gui.register("WIModelEditorMeshes", gui.WIModelEditorMeshes)
