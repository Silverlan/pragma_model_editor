-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("gui.WIModelViewer", gui.Base)

include("/gui/witabbedpanel.lua")
include("/gui/wimodelview.lua")
include("/gui/layout/aspect_ratio.lua")
include("/gui/layout/vbox.lua")
include("/gui/resizer.lua")
include("editor_base.lua")
include("editor_info.lua")
include("editor_animations.lua")
include("editor_skeleton.lua")
include("editor_meshes.lua")
include("editor_attachments.lua")
include("editor_blend_controllers.lua")
include("editor_physics.lua")
include("editor_textures.lua")
include("editor_wireframe_mesh.lua")
include("editor_hitboxes.lua")
include("editor_flexes.lua")

locale.load("model_editor.txt")

gui.WIModelViewer.IMPORT_TYPE_MESH = 1
gui.WIModelViewer.IMPORT_TYPE_PHYSICS = 2
gui.WIModelViewer.IMPORT_TYPE_ANIMATION = 4
gui.WIModelViewer.importers = {}
gui.WIModelViewer.register_importer = function(ext, importTypes, fImport)
	gui.WIModelViewer.importers[ext:lower()] = { importTypes, fImport }
end
for _, f in ipairs(file.find("lua/" .. get_script_path() .. "/importers/*.lua")) do
	include("importers/" .. f)
end

local MARGIN_X_OFFSET = 20

function gui.WIModelViewer:__init()
	gui.Base.__init(self)

	include("/shaders/mde")
end
function gui.WIModelViewer:OnRemove()
	gui.Base.OnRemove(self)

	if util.is_valid(self.m_cbDropped) == true then
		self.m_cbDropped:Remove()
	end
	if util.is_valid(self.m_entLightSource) then
		self.m_entLightSource:Remove()
	end
end
function gui.WIModelViewer:AddPanel(pTab, p)
	table.insert(self.m_tShowPanel, false)
	table.insert(self.m_tPanels, p)
	table.insert(self.m_tTabs, pTab)
	return #self.m_tPanels
end
function gui.WIModelViewer:GetPanel(i)
	return self.m_tPanels[i]
end
function gui.WIModelViewer:LogMessage(msg)
	-- TODO
end
function gui.WIModelViewer:UpdateShowMeshes()
	if util.is_valid(self.m_pModelView) == false then
		return
	end
	self.m_pModelView:SetShowMeshes(self.m_bShowMeshes)
end
function gui.WIModelViewer:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(1024, 768)

	self.m_bShowRenderBox = false
	self.m_bShowCollisionBox = false
	self.m_bShowWireframe = false
	self.m_bShowVertices = false
	self.m_bShowMeshes = true
	self.m_bShowGround = true

	self.m_tShowPanel = {}
	self.m_tPanels = {}
	self.m_tTabs = {}

	self.m_dsColorWireframe = util.DataStream()
	self.m_dsColorWireframe:WriteVector4(Color.Goldenrod:ToVector4())

	self.m_dsColorVertices = util.DataStream()
	self.m_dsColorVertices:WriteVector4(Color.Red:ToVector4())

	self.m_container = gui.create("vbox", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_container:SetAutoFillContents(true)

	local mdlViewContainer = gui.create("aspect_ratio", self.m_container)
	mdlViewContainer:SetHeight(460)
	self.m_pBg = mdlViewContainer -- TODO

	local pModelView = gui.create("model_view", mdlViewContainer)
	pModelView:AddCallback("OnSceneRender", function(pModelView, drawCmd)
		if self:IsValid() == false then
			return
		end
		self:OnSceneRender(drawCmd, pModelView:GetCamera(), pModelView:GetRenderTarget())
	end)
	pModelView:AddCallback("PrepareRendering", function(pModelView)
		if self:IsValid() == false then
			return
		end
		self:PrepareRendering(pModelView)
		for _, p in ipairs(self.m_tPanels) do
			if util.is_valid(p) == true then
				p:PrepareRendering(pModelView)
			end
		end
	end)
	pModelView:SetRenderFilter(function(ent, mdl, meshGroupId, meshGroup, mesh, subMesh, mat)
		return self:FilterMeshes(ent, mdl, meshGroupId, meshGroup, mesh, subMesh, mat)
	end)
	pModelView:SetClearColor(Color.White)
	pModelView:SetAutoAlignToParent(true)
	pModelView:InitializeViewport()

	gui.create("resizer", self.m_container)

	local pTabPanel = gui.create("tabbed_panel", self.m_container)
	pTabPanel:AddCallback("OnTabSelected", function(pTabbedPanel, pTab, pPanel)
		if self:IsValid() == false then
			return
		end
		self.m_pSelectedTab = pPanel
		for idx, pOther in ipairs(self.m_tPanels) do
			if util.is_valid(pOther) == true then
				local b = (pPanel == pOther:GetParent()) and true or false
				pOther:SetShowItems(b or self.m_tShowPanel[idx])
				pOther:SetSelected(b)
			end
		end
	end)

	self.m_pTabInfo = pTabPanel:AddTab(locale.get_text("info"))
	local pInfo = gui.create("model_editor_info", self.m_pTabInfo)
	self.m_idInfo = self:AddPanel(self.m_pTabInfo, pInfo)
	pInfo:SetAutoAlignToParent(true)
	pInfo:AddCallback("OnOptionChanged", function(pInfo, name, pCb, bActivated)
		if self:IsValid() == false then
			return
		end
		local panelId = -1
		if name == "show_meshes" then
			self.m_bShowMeshes = bActivated
			if util.is_valid(self.m_pModelView) == false then
				return
			end
			self.m_pModelView:SetShowMeshes(bActivated)
		elseif name == "show_hitboxes" then
			panelId = self.m_idHitboxes
		elseif name == "show_skeleton" then
			panelId = self.m_idSkeleton
		elseif name == "show_physics" then
			panelId = self.m_idPhysics
		elseif name == "show_wireframe" then
			self.m_bShowWireframe = bActivated
		elseif name == "show_vertices" then
			self.m_bShowVertices = bActivated
		elseif name == "show_normals" then
		elseif name == "show_tangents" then
		elseif name == "show_bitangents" then
		elseif name == "show_render_box" then
			self.m_bShowRenderBox = bActivated
		elseif name == "show_collision_box" then
			self.m_bShowCollisionBox = bActivated
		elseif name == "show_ground" then
			self.m_bShowGround = bActivated
			if util.is_valid(self.m_pModelView) then
				self.m_pModelView:SetGroundVisible(bActivated)
			end
		elseif name == "play_sounds" then
			if util.is_valid(self.m_pModelView) == true then
				local ent = self.m_pModelView:GetEntity()
				if util.is_valid(ent) == false then
					return
				end
				local mdlPreviewComponent = ent:GetComponent(ents.COMPONENT_MDE_MODEL_PREVIEW)
				if mdlPreviewComponent ~= nil then
					mdlPreviewComponent:SetShouldPlaySounds(bActivated)
				end
			end
		elseif name == "enable_lighting" then
			if util.is_valid(self.m_pModelView) == true then
				self.m_pModelView:SetLightingEnabled(bActivated)
			end
		elseif name == "show_movement" then
			if util.is_valid(self.m_pModelView) == true then
				local ent = self.m_pModelView:GetEntity()
				if util.is_valid(ent) == false then
					return
				end
				local mdlPreviewComponent = ent:GetComponent(ents.COMPONENT_MDE_MODEL_PREVIEW)
				if mdlPreviewComponent ~= nil then
					mdlPreviewComponent:SetShouldShowMovement(bActivated)
				end
			end
		elseif name == "animated" then
			if util.is_valid(self.m_pModelView) == true then
				local ent = self.m_pModelView:GetEntity()
				ent:SetAnimated(bActivated)
			end
		end
		local pTgt = self:GetPanel(panelId)
		if util.is_valid(pTgt) == true then
			self.m_tShowPanel[panelId] = bActivated
			pTgt:SetShowItems(bActivated)
		end
	end)

	self.m_pTabAnimations = pTabPanel:AddTab(locale.get_text("animations"))
	local pAnimations = gui.create("model_editor_animations", self.m_pTabAnimations)
	self.m_idAnimations = self:AddPanel(self.m_pTabAnimations, pAnimations)
	pAnimations:SetAutoAlignToParent(true)
	pAnimations:AddCallback("OnAnimationSelected", function(pAnimations, anim)
		if self:IsValid() == false then
			return
		end
		self:PlayAnimation(anim)
	end)

	self.m_pTabSkeleton = pTabPanel:AddTab(locale.get_text("skeleton"))
	local pSkeleton = gui.create("model_editor_skeleton", self.m_pTabSkeleton)
	self.m_idSkeleton = self:AddPanel(self.m_pTabSkeleton, pSkeleton)
	pSkeleton:SetAutoAlignToParent(true)

	self.m_pTabMeshes = pTabPanel:AddTab(locale.get_text("mde_meshes"))
	local pMeshes = gui.create("model_editor_meshes", self.m_pTabMeshes)
	self.m_idMeshes = self:AddPanel(self.m_pTabMeshes, pMeshes)
	pMeshes:SetAutoAlignToParent(true)

	self.m_pTabAttachments = pTabPanel:AddTab(locale.get_text("attachments"))
	local pAttachments = gui.create("model_editor_attachments", self.m_pTabAttachments)
	self.m_idAttachments = self:AddPanel(self.m_pTabAttachments, pAttachments)
	pAttachments:SetAutoAlignToParent(true)

	self.m_pTabBlendControllers = pTabPanel:AddTab(locale.get_text("blendcontrollers"))
	local pBlendControllers = gui.create("model_editor_blend_controllers", self.m_pTabBlendControllers)
	self.m_idBlendControllers = self:AddPanel(self.m_pTabBlendControllers, pBlendControllers)
	pBlendControllers:SetAutoAlignToParent(true)
	pBlendControllers:AddCallback("OnBlendControllerChanged", function(pBlendControllers, blendController, value)
		if self:IsValid() == false then
			return
		end
		if util.is_valid(self.m_pModelView) == false then
			return
		end
		local ent = self.m_pModelView:GetEntity()
		local animComponent = util.is_valid(ent) and ent:GetComponent(ents.COMPONENT_ANIMATED) or nil
		if animComponent == nil then
			return
		end
		animComponent:SetBlendController(blendController, value)
	end)

	self.m_pTabBodygroups = pTabPanel:AddTab(locale.get_text("bodygroups"))
	--local pBodygroups = gui.create("model_editor_hitboxes",self.m_pTabBodygroups)
	--self.m_pBodygroups = pBodygroups
	--pBodygroups:SetEditor(self)
	--pBodygroups:SetAutoAlignToParent(true)

	self.m_pTabSkins = pTabPanel:AddTab(locale.get_text("skins"))
	--local pTabSkins = gui.create("model_editor_hitboxes",self.m_pTabSkins)
	--self.m_pTabSkins = pTabSkins
	--pTabSkins:SetEditor(self)
	--pTabSkins:SetAutoAlignToParent(true)

	self.m_pTabPhysics = pTabPanel:AddTab(locale.get_text("physics"))
	local pPhysics = gui.create("model_editor_physics", self.m_pTabPhysics)
	self.m_idPhysics = self:AddPanel(self.m_pTabPhysics, pPhysics)
	pPhysics:SetAutoAlignToParent(true)

	self.m_pTabHitboxes = pTabPanel:AddTab(locale.get_text("hitboxes"))
	local pHitboxes = gui.create("model_editor_hitboxes", self.m_pTabHitboxes)
	self.m_idHitboxes = self:AddPanel(self.m_pTabHitboxes, pHitboxes)
	pHitboxes:SetAutoAlignToParent(true)

	self.m_TabFlexes = pTabPanel:AddTab(locale.get_text("flexes"))
	local pFlexes = gui.create("model_editor_flexes", self.m_TabFlexes)
	self.m_idFlexes = self:AddPanel(self.m_TabFlexes, pFlexes)
	pFlexes:SetAutoAlignToParent(true)

	self.m_pTabTextures = pTabPanel:AddTab(locale.get_text("textures"))
	local pTextures = gui.create("model_editor_textures", self.m_pTabTextures)
	self.m_idTextures = self:AddPanel(self.m_pTabTextures, pTextures)
	pTextures:SetAutoAlignToParent(true)

	pTabPanel:Update()

	-- TODO
	--[[local entLight = ents.create("env_light_environment")
	if(entLight ~= nil) then
		local trComponent = entLight:GetComponent(ents.COMPONENT_TRANSFORM)
		if(trComponent ~= nil) then
			trComponent:SetPos(Vector(-0.642459,-0.642788,-0.417218))
		end
		local colComponent = entLight:GetComponent(ents.COMPONENT_COLOR)
		if(colComponent ~= nil) then
			colComponent:SetColor(Color(800,540,430,500))
		end
		local lightComponent = entLight:GetComponent(ents.COMPONENT_LIGHT)
		if(lightComponent ~= nil) then
			lightComponent:SetShadowType(ents.LightComponent.SHADOW_TYPE_NONE)
			lightComponent:SetAddToGameScene(false)
		end
		entLight:Spawn()
		if(lightComponent ~= nil) then
			pModelView:AddLightSource(lightComponent)
		end
	end

	local ent = ents.create("env_light_spot")
	ent:SetPos(Vector(32,64,20) *1)
	ent:SetKeyValue("spawnflags",tostring(1024))
	local colComponent = ent:GetComponent(ents.COMPONENT_COLOR)
	if(colComponent ~= nil) then colComponent:SetColor(light.color_temperature_to_color(2700)) end
	local radiusComponent = ent:GetComponent(ents.COMPONENT_RADIUS)
	if(radiusComponent ~= nil) then radiusComponent:SetRadius(300) end
	-- TODO: Exponent factor -> Never reduce
	local lightC = ent:GetComponent(ents.COMPONENT_LIGHT)
	if(lightC ~= nil) then
		lightC:SetLightIntensity(100)
		lightC:SetShadowType(ents.LightComponent.SHADOW_TYPE_NONE)
		lightC:SetAddToGameScene(false)
	end
	local lightSpotC = ent:GetComponent(ents.COMPONENT_LIGHT_SPOT)
	if(lightSpotC ~= nil) then
		lightSpotC:SetInnerCutoffAngle(35)
		lightSpotC:SetOuterCutoffAngle(45)
	end
	ent:Spawn()
	self.m_entLightSource = ent

	local toggleC = ent:GetComponent(ents.COMPONENT_TOGGLE)
	if(toggleC ~= nil) then toggleC:TurnOn() end

	pModelView:AddLightSource(lightC)]]

	--[[pModelView:AddCallback("OnMouseEvent",function(p,button,action,mods)
		if(button == input.MOUSE_BUTTON_RIGHT) then
			if(action == input.STATE_PRESS) then
				local cam = pModelView:GetCamera()
				if(cam ~= nil) then
					local uv = pModelView:GetCursorPos()
					uv.x = uv.x /pModelView:GetWidth()
					uv.y = uv.y /pModelView:GetHeight()
					self.m_selectUvStart = uv
				end
			elseif(action == input.STATE_RELEASE and self.m_selectUvStart ~= nil) then
				local uvStart = self.m_selectUvStart
				self.m_selectUvStart = nil
				local mdl = pModelView:GetModel()
				local cam = pModelView:GetCamera()
				if(mdl == nil or cam == nil) then return end
				local uv = pModelView:GetCursorPos()
				uv.x = uv.x /pModelView:GetWidth()
				uv.y = uv.y /pModelView:GetHeight()
				local planes = cam:CreateFrustumKDop(uvStart,uv)
				
				local mesh = mdl:GetMeshGroup(0):GetMeshes()[1]:GetSubMeshes()[1]
				local verts = mesh:GetVertices()
				local numVertsSelected = 0
				for _,v in ipairs(verts) do
					if(intersect.point_in_plane_mesh(v,planes) == true) then
						numVertsSelected = numVertsSelected +1
					end
				end
				print("Vertices in selection: ",numVertsSelected)
			end
		end
	end)]]
	self.m_pModelView = pModelView

	local ent = pModelView:GetEntity()
	for _, p in ipairs(self.m_tPanels) do
		if util.is_valid(p) == true then
			p:SetEditor(self)
			p:SetEntity(ent)
		end
	end

	self.m_cbDropped = game.add_callback("OnFilesDropped", function(tFiles)
		if self:IsValid() == false or util.is_valid(self.m_model) == false then
			return
		end
		local update = 0
		local textureFiles = {}
		for i, fName in ipairs(tFiles) do
			local ext = file.get_file_extension(fName)
			if ext ~= nil and (ext == ".ktx" or ext == ".dds" or ext == ".png" or ext == ".tga" or ext == ".vtf") then
				table.insert(textureFiles, { fName, fName:sub(1, -(#ext + 1)) })
			end
		end
		local bReloadMaterials = false
		local function save_textures(mdlName, textures)
			local relTexPath = "models/" .. mdlName
			local bFirst = true
			for _, tex in ipairs(textures) do
				tex = tex:lower()
				local ext = file.get_file_extension(tex)
				if ext ~= nil then
					tex = tex:sub(1, -#ext - 2)
				end
				local bValidTexture = false
				for _, f in ipairs(textureFiles) do
					local fName = f[2]:lower()
					if tex == fName then
						bReloadMaterials = true
						local texPath = "materials/" .. relTexPath
						file.create_path(texPath)
						local fIn = game.open_dropped_file(f[1], true)
						if fIn ~= nil then
							local fOut = file.open(texPath .. "/" .. f[1], "wb")
							if fOut ~= nil then
								if bFirst == true then
									self.m_model:AddTexturePath(relTexPath)
									self:LogMessage(
										"All model textures have been copied to '"
											.. relTexPath
											.. "' and appropriate material files have been generated!"
									)
									bFirst = false
								end
								bValidTexture = true
								local ds = fIn:Read(fIn:Size())
								fOut:Write(ds) -- Copy contents
								fOut:Close()

								local fMat = file.open(texPath .. "/" .. f[2] .. ".wmi", "w")
								if fMat ~= nil then
									fMat:WriteString(
										'"textured"\n{\n\t$texture diffusemap "'
											.. relTexPath
											.. "/"
											.. f[2]
											.. '"\n}\n'
									)
									fMat:Close()
								end
							end
							fIn:Close()
						end
						break
					end
				end
				self:LogMessage(
					"WARNING: Texture '" .. tex .. "' required for model '" .. mdlName .. "' not found in input files!"
				)
			end
		end
		local nFiles = #tFiles
		while nFiles > 0 do
			local i = nFiles
			local fName = tFiles[i]
			local ext = file.get_file_extension(fName)
			if ext ~= nil then
				local importer = self.importers[ext]
				local fOpen = function(bBinary)
					return game.open_dropped_file(fName, bBinary)
				end
				local type = (self.m_pSelectedTab == self.m_pTabPhysics) and self.IMPORT_TYPE_PHYSICS
					or self.IMPORT_TYPE_MESH
				if importer ~= nil and bit.band(importer[1], type) ~= 0 then
					local mdlName = fName:sub(1, -(#ext + 2))
					local r, textures = importer[2](self, self.m_model, mdlName, fOpen, type, tFiles)
					if r == true then
						update = 3
						if textures ~= nil then
							save_textures(mdlName, textures)
						end
					end
				end
			end
			nFiles = #tFiles
			if nFiles > 0 and tFiles[nFiles] == fName then
				table.remove(tFiles, nFiles) -- Remove last element (if it hasn't been removed by the importer yet)
				nFiles = nFiles - 1
			end
		end
		if bit.band(update, 2) ~= 0 then
			self.m_model:Update()
		end
		if bReloadMaterials == true then
			self.m_model:LoadMaterials(true)
		end
		if bit.band(update, 1) ~= 0 then
			self:SetModel(self.m_model)
		end
	end)

	self.m_shaderSkeleton = shader.get("mde_skeleton")
	self.m_shaderWireframe = shader.get("mde_wireframe")
	self.m_shaderWireframeSimple = shader.get("mde_wireframe_simple")
	self.m_shaderPoints = shader.get("mde_points")
	self.m_shaderVerticesAnimated = shader.get("mde_vertices_animated")

	self.m_axisWireframeMesh = WIModelEditorWireframeMesh({
		Vector(0.0, 0.0, 0.0),
		Vector(1.0, 0.0, 0.0),

		Vector(0.0, 0.0, 0.0),
		Vector(0.0, 1.0, 0.0),

		Vector(0.0, 0.0, 0.0),
		Vector(0.0, 0.0, 1.0),
	}, {
		Color.Red,
		Color.Red,

		Color.Lime,
		Color.Lime,

		Color.Blue,
		Color.Blue,
	})

	self.m_boxWireframeMesh = WIModelEditorWireframeMesh(self:GetBoxVertices(), {
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
		Color.Red,
	})
	self:Clear()
end
local startPos = Vector(-1, -1, -1)
local endPos = Vector(1, 1, 1)
local boxVerts = {
	startPos,
	Vector(startPos.x, startPos.y, endPos.z),
	startPos,
	Vector(endPos.x, startPos.y, startPos.z),
	startPos,
	Vector(startPos.x, endPos.y, startPos.z),
	Vector(startPos.x, startPos.y, endPos.z),
	Vector(endPos.x, startPos.y, endPos.z),
	Vector(startPos.x, startPos.y, endPos.z),
	Vector(startPos.x, endPos.y, endPos.z),
	Vector(endPos.x, startPos.y, endPos.z),
	Vector(endPos.x, startPos.y, startPos.z),
	Vector(endPos.x, startPos.y, endPos.z),
	endPos,
	Vector(endPos.x, startPos.y, startPos.z),
	Vector(endPos.x, endPos.y, startPos.z),
	Vector(startPos.x, endPos.y, startPos.z),
	Vector(startPos.x, endPos.y, endPos.z),
	Vector(startPos.x, endPos.y, startPos.z),
	Vector(endPos.x, endPos.y, startPos.z),
	endPos,
	Vector(endPos.x, endPos.y, startPos.z),
	endPos,
	Vector(startPos.x, endPos.y, endPos.z),
}
function gui.WIModelViewer:GetBoxVertices()
	return boxVerts
end
function gui.WIModelViewer:PrepareRendering(pModelView)
	if self.m_bShowWireframe then
		pModelView:ScheduleEntityForRendering(self.m_shaderWireframe)
	end
	if self.m_bShowVertices then
		pModelView:ScheduleEntityForRendering(self.m_shaderPoints)
	end
end
function gui.WIModelViewer:ScheduleEntityForRendering()
	if util.is_valid(self.m_pModelView) == false then
		return
	end
	self.m_pModelView:Render()
end
function gui.WIModelViewer:DrawAxis(m)
	if util.is_valid(self.m_axisWireframeMesh) == false or util.is_valid(self.m_pModelView) == false then
		return
	end
	local rt = self.m_pModelView:GetRenderTarget()
	local cam = self.m_pModelView:GetCamera()
	m = cam:GetProjectionMatrix() * cam:GetViewMatrix() * m
	self.m_axisWireframeMesh:Draw(rt, m)
end
function gui.WIModelViewer:DrawBox(m)
	if util.is_valid(self.m_boxWireframeMesh) == false or util.is_valid(self.m_pModelView) == false then
		return
	end
	local rt = self.m_pModelView:GetRenderTarget()
	local cam = self.m_pModelView:GetCamera()
	m = cam:GetProjectionMatrix() * cam:GetViewMatrix() * m
	self.m_boxWireframeMesh:Draw(rt, m)
end
function gui.WIModelViewer:DrawMesh(mesh, m)
	if util.is_valid(self.m_pModelView) == false then
		return
	end
	local rt = self.m_pModelView:GetRenderTarget()
	local cam = self.m_pModelView:GetCamera()
	m = cam:GetProjectionMatrix() * cam:GetViewMatrix() * m
	mesh:Draw(rt, m)
end
function gui.WIModelViewer:GetModel()
	if util.is_valid(self.m_pModelView) == false then
		return
	end
	return self.m_pModelView:GetModel()
end
function gui.WIModelViewer:GetModelName()
	return self.m_modelName
end
function gui.WIModelViewer:GetEntity()
	if util.is_valid(self.m_pModelView) == false then
		return
	end
	return self.m_pModelView:GetEntity()
end
function gui.WIModelViewer:SetLOD(lod)
	self.m_lodMeshes = {}
	local mdl = self:GetModel()
	if util.is_valid(mdl) == false then
		return
	end
	self.m_lodMeshes = mdl:GetBodyGroupMeshes(lod)
end
function gui.WIModelViewer:FilterMeshes(ent, mdl, meshGroupId, meshGroup, mesh, subMesh, mat)
	for _, meshLod in ipairs(self.m_lodMeshes) do
		if meshLod == mesh then
			return true
		end
	end
	return true
end
function gui.WIModelViewer:RenderWireframe()
	local shaderWireframe = self.m_shaderWireframeAnimated
	if shaderWireframe == nil or util.is_valid(self.m_pModelView) == false then
		return
	end
	self.m_pModelView:RenderEntity(shaderWireframe, nil, nil, function(shaderWireframe, drawCmd)
		return shaderWireframe:RecordPushConstants(
			self.m_dsColorWireframe,
			shader.TexturedLit3D.PUSH_CONSTANTS_USER_DATA_OFFSET
		)
	end)
end
function gui.WIModelViewer:RenderVertices()
	local shaderVertices = self.m_shaderVerticesAnimated
	if shaderVertices == nil or util.is_valid(self.m_pModelView) == false then
		return
	end
	self.m_pModelView:RenderEntity(shaderVertices, nil, nil, function(shaderVertices, drawCmd)
		return shaderVertices:RecordPushConstants(
			self.m_dsColorVertices,
			shader.TexturedLit3D.PUSH_CONSTANTS_USER_DATA_OFFSET
		)
	end)
end
function gui.WIModelViewer:GetModelView()
	return self.m_pModelView
end
function gui.WIModelViewer:OnSceneRender(drawCmd, cam, rt)
	for _, p in ipairs(self.m_tPanels) do
		if util.is_valid(p) == true then
			p:Render(drawCmd, cam, self.m_pModelView)
		end
	end

	local mdl = self:GetModel()
	if util.is_valid(mdl) == false then
		return
	end
	if self.m_bShowWireframe == true then
		self:RenderWireframe()
	end
	if self.m_bShowVertices == true then
		self:RenderVertices()
	end
	if self.m_bShowRenderBox == true then
		local min, max = mdl:GetRenderBounds()
		local center = (min + max) / 2.0
		local bounds = (max - min) / 2.0

		local m = Mat4(1.0)
		m:Translate(center)
		m:Scale(bounds)
		self:DrawBox(m)
	end
	if self.m_bShowCollisionBox == true then
		local min, max = mdl:GetCollisionBounds()
		local center = (min + max) / 2.0
		local bounds = (max - min) / 2.0

		local m = Mat4(1.0)
		m:Translate(center)
		m:Scale(bounds)
		self:DrawBox(m)
	end
end
function gui.WIModelViewer:Clear()
	self:SetModel()
end
function gui.WIModelViewer:SaveModel(mdlName)
	if util.is_valid(self.m_model) == false then
		return
	end
	if file.get_file_extension(mdlName) ~= "wmd" then
		mdlName = mdlName .. ".wmd"
	end
	self.m_model:Save(mdlName)
end
function gui.WIModelViewer:UpdateModel()
	if util.is_valid(self.m_pModelView) == false then
		return
	end
	self.m_pModelView:UpdateModel()
end
function gui.WIModelViewer:SetModel(mdlName)
	local mdl
	if mdlName ~= nil then
		if type(mdlName) == "string" then
			mdl = game.load_model(mdlName)
		else
			mdl = mdlName
			-- if(mdl ~= self.m_model) then mdl = mdl:Copy() end -- TODO: Copy the model if we're doing editing?
		end
	else
		mdl = game.create_model(false)
	end
	if mdl == self.m_model then
		return
	end
	self.m_model = mdl
	self.m_modelName = mdlName
	if util.is_valid(self.m_pModelView) then
		self.m_pModelView:SetModel(mdl)
	end
	for _, p in ipairs(self.m_tPanels) do
		if util.is_valid(p) == true then
			p:SetModel(mdl)
		end
	end
	self:SetLOD(0)
end
function gui.WIModelViewer:PlayAnimation(anim)
	if util.is_valid(self.m_pModelView) == false then
		return
	end
	self.m_pModelView:PlayAnimation(anim)
end
function gui.WIModelViewer:OnSizeChanged(w, h)
	gui.Base.OnSizeChanged(self, w, h)
	if util.is_valid(self.m_pTabSkeleton) == true then
		local pBones = self.m_pTabSkeleton.m_pBones
		if util.is_valid(pBones) == true then
			pBones:SetSize(w - pBones:GetX(), h)
		end
	end
end
gui.register("model_viewer", gui.WIModelViewer)
