-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("gui.WIModelEditorTextures", gui.Base, gui.WIModelEditorPanel)

function gui.WIModelEditorTextures:__init()
	gui.Base.__init(self)
	gui.WIModelEditorPanel.__init(self)
end
function gui.WIModelEditorTextures:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_selectedTexture = ""
	self.m_shader = shader.get("mde_flat_animated")

	local pContainer = gui.create("WIGridPanel", self)
	pContainer:SetAutoAlignToParent(true)
	self.m_pContainer = pContainer

	local pLbMatPaths = gui.create("WIText")
	pLbMatPaths:SetText(locale.get_text("mde_material_paths") .. ":")
	pLbMatPaths:SizeToContents()
	pContainer:AddItem(pLbMatPaths, 0, 0)

	local pPaths = gui.create("WITable")
	pPaths:SetScrollable(true)
	pPaths:SetSelectableMode(gui.Table.SELECTABLE_MODE_SINGLE)
	pPaths:SetRowHeight(20)

	local pHeaderPaths = pPaths:AddHeaderRow()
	pHeaderPaths:SetValue(0, locale.get_text("id"))
	pHeaderPaths:SetValue(1, locale.get_text("path"))
	pHeaderPaths:SetValue(2, locale.get_text("action"))

	self.m_pTexturePaths = pPaths
	pContainer:AddItem(pPaths, 1, 0)

	local pLbTextures = gui.create("WIText")
	pLbTextures:SetText(locale.get_text("textures") .. ":")
	pLbTextures:SizeToContents()
	pContainer:AddItem(pLbTextures, 2, 0)

	local pTextures = gui.create("WITable")
	pTextures:SetScrollable(true)
	pTextures:SetSelectableMode(gui.Table.SELECTABLE_MODE_SINGLE)
	pTextures:SetRowHeight(20)
	pTextures:SetMouseInputEnabled(true)
	pTextures:AddCallback("OnMouseEvent", function(pTextures, button, action, mods)
		if self:IsValid() == false then
			return
		end
		if button == input.MOUSE_BUTTON_RIGHT and action == input.STATE_PRESS then
			local menu = gui.open_context_menu()
			menu:AddItem(locale.get_text("mde_add_texture"), function(pItem)
				local pDialog = gui.create_file_open_dialog(function(pDialog, fName)
					if self:IsValid() == false or util.is_valid(self.m_model) == false then
						return
					end
					fName = fName:sub(11) -- Path without "materials/"
					self.m_model:AddTexturePath(file.get_file_path(fName))
					self.m_model:AddMaterial(0, file.get_file_name(fName))
					self.m_model:LoadMaterials()
					self:SetModel(self.m_model)
				end)
				pDialog:SetRootPath("materials/")
				pDialog:SetExtensions({ "wmi", "vmt" })
				pDialog:Update()
			end)
			menu:AddItem(locale.get_text("mde_remove_selected"), function(pItem)
				local pSelected = pTextures:GetFirstSelectedRow()
				if util.is_valid(pSelected) == false then
					return
				end
				local texName = pSelected:GetValue(0)

				-- TODO Get Name
			end)
			menu:AddItem(locale.get_text("clear"), function(pItem) end)
			menu:Update()
		end
	end)

	local pHeader = pTextures:AddHeaderRow()
	pHeader:SetValue(0, locale.get_text("id"))
	pHeader:SetValue(1, locale.get_text("texture"))
	pHeader:SetValue(2, locale.get_text("material"))
	pHeader:SetValue(3, locale.get_text("action"))

	self.m_pTextures = pTextures
	pContainer:AddItem(pTextures, 3, 0)

	local pRefresh = gui.create("WIButton")
	pRefresh:SetText(locale.get_text("refresh"))
	pRefresh:AddCallback("OnPressed", function(pButton)
		if self:IsValid() == false or util.is_valid(self.m_model) == false then
			return
		end
		self.m_model:LoadMaterials()
		self:SetModel(self.m_model)
	end)
	pContainer:AddItem(pRefresh, 4, 0)
end
local hullColor = Color.LawnGreen:Copy()
hullColor.a = 128
hullColor = hullColor:ToVector4()

local dsColor = util.DataStream()
dsColor:WriteVector4(hullColor)

function gui.WIModelEditorTextures:PrepareRendering(pModelView)
	if self:GetShowItems() == false then
		return
	end
	pModelView:ScheduleEntityForRendering(self.m_shader, nil, function(ent, mdl, mesh, subMesh, mat)
		return mat:GetName() == self.m_selectedTexture
	end)
end
function gui.WIModelEditorTextures:Render(drawCmd, cam)
	local pEditor = self:GetEditor()
	if self:GetShowItems() == false or self.m_shader == nil or util.is_valid(pEditor) == false then
		return
	end
	local pModelView = pEditor:GetModelView()
	if util.is_valid(pModelView) == false then
		return
	end

	local shaderTex = self.m_shader
	pModelView:RenderEntity(
		shaderTex,
		function(ent, mdl, meshGroupId, meshGroup, mesh, subMesh, mat)
			return (mat:GetName() == self.m_selectedTexture) and true or false
		end,
		drawCmd,
		function(shaderTex, drawCmd)
			return shaderTex:RecordPushConstants(dsColor, shader.TexturedLit3D.PUSH_CONSTANTS_USER_DATA_OFFSET)
		end
	)
end
function gui.WIModelEditorTextures:SetModel(mdl)
	self.m_model = mdl
	if util.is_valid(mdl) == false then
		return
	end
	local pPaths = self.m_pTexturePaths
	if util.is_valid(pPaths) == true then
		pPaths:Clear()
		for idx, path in ipairs(mdl:GetMaterialPaths()) do
			local pRow = pPaths:AddRow()
			pRow:SetValue(0, tostring(idx))
			pRow:SetValue(1, path)

			local pButton = gui.create("WIButton")
			pButton:SetText(locale.get_text("remove"))
			pButton:AddCallback("OnPressed", function(pButton)
				if self:IsValid() == false or util.is_valid(mdl) == false or util.is_valid(pPaths) == false then
					return
				end
				mdl:RemoveTexturePath(idx - 1)
				self:SetModel(mdl)
			end)
			pRow:InsertElement(2, pButton)
		end
	end

	local pTextures = self.m_pTextures
	if util.is_valid(pTextures) == true then
		pTextures:Clear()

		local mats = mdl:GetMaterials()
		local textures = mdl:GetMaterialNames()
		for idx, tex in ipairs(textures) do
			local pRow = pTextures:AddRow()
			pRow:AddCallback("OnSelected", function(pRow)
				if self:IsValid() == false then
					return
				end
				self:GetEditor():ScheduleEntityForRendering()
				self.m_selectedTexture = pRow:GetValue(2)
			end)
			local mat = mats[idx]
			local matName = locale.get_text("not_found")
			if util.is_valid(mat) == true then
				matName = mat:GetName()
			end
			pRow:SetValue(0, tostring(idx))
			pRow:SetValue(1, tex)
			pRow:SetValue(2, matName)

			local pButton = gui.create("WIButton")
			pButton:SetText(locale.get_text("remove"))
			pButton:AddCallback("OnPressed", function(pButton)
				if self:IsValid() == false or util.is_valid(mdl) == false or util.is_valid(pPaths) == false then
					return
				end
				mdl:RemoveTexture(idx - 1)
				self:SetModel(mdl)
			end)
			pRow:InsertElement(3, pButton)
		end
	end
	local pEditor = self:GetEditor()
	if util.is_valid(pEditor) == true then
		pEditor:UpdateModel()
	end
end
function gui.WIModelEditorTextures:OnSizeChanged(w, h)
	gui.Base.OnSizeChanged(self, w, h)
	if util.is_valid(self.m_pTextures) == true then
		self.m_pTextures:SetSize(w, 128)
	end
	if util.is_valid(self.m_pTexturePaths) == true then
		self.m_pTexturePaths:SetSize(w, 128)
	end
end
gui.register("WIModelEditorTextures", gui.WIModelEditorTextures)
