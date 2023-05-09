include("/gui/vbox.lua")
include("/gui/hbox.lua")

util.register_class("gui.WIModelEditorInfo", gui.Base, gui.WIModelEditorPanel)

function gui.WIModelEditorInfo:__init()
	gui.Base.__init(self)
end
function gui.WIModelEditorInfo:AddOption(name, identifier)
	local optionBox = gui.create("WIHBox", self.m_optionsBox)

	local pCbOption = gui.create("WICheckbox", optionBox)
	pCbOption:AddCallback("OnChange", function(pCb, b)
		local pEditor = self:GetEditor()
		if util.is_valid(pEditor) then
			pEditor:ScheduleEntityForRendering()
		end
		self:CallCallbacks("OnOptionChanged", identifier, pCb, b)
	end)

	gui.create("WIBase", optionBox, 0, 0, 5, 1) -- gap

	local pLb = gui.create("WIText", optionBox)
	pLb:SetText(name)
	pLb:SizeToContents()

	table.insert(self.m_tOptions, { pLb, pCbOption })
	return pCbOption
end
function gui.WIModelEditorInfo:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(600, 300)

	self.m_infoBox = gui.create("WIVBox", self, 20, 24)
	self.m_optionsBox = gui.create("WIVBox", self, self:GetWidth() - 200, 24)
	self.m_tInfos = {}
	self.m_tOptions = {}

	local pOpt = self:AddOption(locale.get_text("mde_show_meshes"), "show_meshes")
	pOpt:SetChecked(true)
	self:AddOption(locale.get_text("mde_show_hitboxes"), "show_hitboxes")
	self:AddOption(locale.get_text("mde_show_skeleton"), "show_skeleton")
	self:AddOption(locale.get_text("mde_show_physics"), "show_physics")
	self:AddOption(locale.get_text("mde_show_wireframe"), "show_wireframe")
	self:AddOption(locale.get_text("mde_show_vertices"), "show_vertices")
	self:AddOption(locale.get_text("mde_show_normals"), "show_normals")
	self:AddOption(locale.get_text("mde_show_tangents"), "show_tangents")
	self:AddOption(locale.get_text("mde_show_bitangents"), "show_bitangents")
	self:AddOption(locale.get_text("mde_show_render_box"), "show_render_box")
	self:AddOption(locale.get_text("mde_show_collision_box"), "show_collision_box")
	self:AddOption(locale.get_text("mde_show_ground"), "show_ground")
	self:AddOption(locale.get_text("mde_play_sounds"), "play_sounds")
	self:AddOption(locale.get_text("mde_enable_lighting"), "enable_lighting"):SetChecked(true)
	self:AddOption(locale.get_text("mde_show_movement"), "show_movement")
	pOpt = self:AddOption(locale.get_text("mde_animated"), "animated")
	pOpt:SetChecked(true)

	-- LOD Level
	local lodBox = gui.create("WIHBox", self.m_optionsBox)
	local lb = gui.create_label(locale.get_text("mde_lod_level"), lodBox)
	local dm = gui.create("WIDropDownMenu", lodBox)
	dm:SetSize(140, 20)
	dm:AddCallback("OnOptionSelected", function(pDm, idx)
		if self:IsValid() == false then
			return
		end
		local pEditor = self:GetEditor()
		if util.is_valid(pEditor) == false then
			return
		end
		pEditor:ScheduleEntityForRendering()
		pEditor:SetLOD(tonumber(pDm:GetOptionValue(idx)))
	end)
	self.m_dmLods = dm
	table.insert(self.m_tOptions, { dm, lb })

	-- Rotate model
	local rotateBox = gui.create("WIHBox", self.m_optionsBox)
	local te = gui.create("WITextEntry", rotateBox)
	te:SetSize(140, 20)
	te:SetText("0 0 0")
	local bt = gui.create("WIButton", rotateBox)
	bt:SetText(locale.get_text("mde_rotate"))
	bt:SetSize(140, 20)
	bt:AddCallback("OnPressed", function(pButton)
		local pEditor = self:GetEditor()
		local mdl = pEditor:GetModel()
		if mdl == nil then
			return
		end
		local rot = te:GetText()
		rot = string.split(rot, " ")
		local ang = EulerAngles(
			(rot[1] ~= nil) and tonumber(rot[1]) or 0.0,
			(rot[2] ~= nil) and tonumber(rot[2]) or 0.0,
			(rot[3] ~= nil) and tonumber(rot[3]) or 0.0
		)
		mdl:Rotate(ang:ToQuaternion())
	end)
	table.insert(self.m_tOptions, { bt, te })

	-- Save
	local bt = gui.create("WIButton", self.m_optionsBox)
	bt:SetText(locale.get_text("save"))
	bt:SetSize(140, 20)
	bt:AddCallback("OnPressed", function(pButton)
		local pEditor = self:GetEditor()
		local mdl = pEditor:GetModel()
		if mdl == nil then
			return
		end
		local mdlName = mdl:GetName()
		if #mdlName == 0 then
			console.print_warning("Unable to save model: Model has no name!")
			return
		end
		if mdl:Save(mdlName) == true then
			console.print("Successfully saved model as '" .. mdlName .. "'!")
		else
			console.print_warning("Unable to save model as '" .. mdlName .. "'!")
		end
	end)
end
function gui.WIModelEditorInfo:SetInfoText(i, text)
	if util.is_valid(self.m_tInfos[i]) == false then
		local pText = gui.create("WIText", self.m_infoBox)
		self.m_tInfos[i] = pText
	end
	local pText = self.m_tInfos[i]
	pText:SetText(text)
	pText:SizeToContents()
end
function gui.WIModelEditorInfo:SetModel(mdl)
	if util.is_valid(mdl) == false then
		for _, pInfo in ipairs(self.m_tInfos) do
			if util.is_valid(pInfo) == true then
				pInfo:Remove()
			end
		end
		self.m_tInfos = {}
		return
	end
	local minRender, maxRender = mdl:GetRenderBounds()
	local minCol, maxCol = mdl:GetCollisionBounds()
	local i = 1
	self:SetInfoText(i, locale.get_text("mde_info_model_name") .. ": " .. mdl:GetName())
	i = i + 1
	self:SetInfoText(i, locale.get_text("mass") .. ": " .. mdl:GetMass())
	i = i + 1
	self:SetInfoText(i, locale.get_text("mde_info_vertex_count") .. ": " .. mdl:GetVertexCount())
	i = i + 1
	self:SetInfoText(i, locale.get_text("mde_info_triangle_count") .. ": " .. mdl:GetTriangleCount())
	i = i + 1
	self:SetInfoText(i, locale.get_text("mde_info_bone_count") .. ": " .. mdl:GetBoneCount())
	i = i + 1
	self:SetInfoText(i, locale.get_text("mde_info_hitbox_count") .. ": " .. mdl:GetHitboxCount())
	i = i + 1
	self:SetInfoText(i, locale.get_text("mde_info_animation_count") .. ": " .. mdl:GetAnimationCount())
	i = i + 1
	self:SetInfoText(i, locale.get_text("mde_info_attachment_count") .. ": " .. mdl:GetAttachmentCount())
	i = i + 1
	self:SetInfoText(i, locale.get_text("mde_info_blend_controller_count") .. ": " .. mdl:GetBlendControllerCount())
	i = i + 1
	self:SetInfoText(i, locale.get_text("mde_info_material_count") .. ": " .. mdl:GetMaterialCount())
	i = i + 1
	self:SetInfoText(i, locale.get_text("mde_info_texture_group_count") .. ": " .. mdl:GetTextureGroupCount())
	i = i + 1
	self:SetInfoText(i, locale.get_text("mde_info_mesh_group_count") .. ": " .. mdl:GetMeshGroupCount())
	i = i + 1
	self:SetInfoText(i, locale.get_text("mde_info_mesh_count") .. ": " .. mdl:GetMeshCount())
	i = i + 1
	self:SetInfoText(i, locale.get_text("mde_info_base_mesh_count") .. ": " .. #mdl:GetBaseMeshGroupIds())
	i = i + 1
	self:SetInfoText(i, locale.get_text("mde_info_collision_mesh_count") .. ": " .. mdl:GetCollisionMeshCount())
	i = i + 1
	self:SetInfoText(
		i,
		locale.get_text("mde_info_render_bounds") .. ": (" .. tostring(minRender) .. ") (" .. tostring(maxRender) .. ")"
	)
	i = i + 1
	self:SetInfoText(
		i,
		locale.get_text("mde_info_collision_bounds") .. ": (" .. tostring(minCol) .. ") (" .. tostring(maxCol) .. ")"
	)
	i = i + 1

	if util.is_valid(self.m_dmLods) == true then
		self.m_dmLods:ClearOptions()
		for i = 1, mdl:GetLODCount() do
			self.m_dmLods:AddOption(tostring(mdl:GetLOD(i - 1)))
		end
	end
end
function gui.WIModelEditorInfo:OnSizeChanged(w, h)
	if util.is_valid(self.m_optionsBox) then
		self.m_optionsBox:SetX(w - self.m_optionsBox:GetWidth() - 20)
	end
end
gui.register("WIModelEditorInfo", gui.WIModelEditorInfo)
