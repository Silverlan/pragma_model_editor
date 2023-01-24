--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/pfm/cursor_tracker.lua")
include("/gui/wiviewport.lua")

util.register_class("gui.WIModelView",gui.Base)

include("wimodelview_bodygroup.lua")

function gui.WIModelView.add_default_actor_context_options(pContext,ent,onApply)
	local mdl = ent:GetModel()
	if(mdl == nil) then return end
	local numSkins = mdl:GetTextureGroupCount()
	local bodyGroups = mdl:GetBodyGroups()
	for i=#bodyGroups,1,-1 do
		local bg = bodyGroups[i]
		if(#bg.meshGroups <= 1) then
			table.remove(bodyGroups,i)
		end
	end
	pContext.impl = pContext.impl or {}
	if(numSkins > 1) then
		local pItem,pSubMenu = pContext:AddSubMenu(locale.get_text("skin"))
		for i=1,numSkins do
			local pItem = pSubMenu:AddItem(tostring(i),function(pItem)
				if(util.is_valid(ent) == false) then return end
				ent:SetSkin(i -1)
				if(onApply) then onApply() end
				pContext.curSkin = nil
			end)
			pItem:AddCallback("OnSelectionChanged",function(pItem,selected)
				if(util.is_valid(ent) == false) then return end
				if(selected) then
					pContext.curSkin = pContext.curSkin or ent:GetSkin()
					ent:SetSkin(i -1)
					if(onApply) then onApply() end
					return
				end
				if(pContext.curSkin == nil or pSubMenu:GetSelectedItem() ~= nil) then return end
				ent:SetSkin(pContext.curSkin)
				if(onApply) then onApply() end
				pContext.curSkin = nil
			end)
		end
		pSubMenu:Update()
	end
	if(#bodyGroups > 0) then
		local pItem,pSubMenu = pContext:AddSubMenu(locale.get_text("bodygroups"))
		for i,bg in ipairs(bodyGroups) do
			local pItem,bgMenu = pSubMenu:AddSubMenu(bg.name)
			for j=1,#bg.meshGroups do
				local pItem = bgMenu:AddItem(tostring(j),function(pItem)
					if(util.is_valid(ent) == false) then return end
					ent:SetBodyGroup(bg.name,j -1)
					if(onApply) then onApply() end
					if(pContext.curBg ~= nil) then pContext.curBg[i] = nil end
				end)
				pItem:AddCallback("OnSelectionChanged",function(pItem,selected)
					if(util.is_valid(ent) == false) then return end
					if(selected) then
						pContext.curBg = pContext.curBg or {}
						pContext.curBg[i] = pContext.curBg[i] or ent:GetBodyGroup(bg.name)
						ent:SetBodyGroup(bg.name,j -1)
						if(onApply) then onApply() end
						return
					end
					if(pContext.curBg == nil or pContext.curBg[i] == nil or pSubMenu:GetSelectedItem() ~= nil) then return end
					ent:SetBodyGroup(bg.name,pContext.curBg[i])
					if(onApply) then onApply() end
					pContext.curBg[i] = nil
				end)
			end
			bgMenu:Update()
		end
		pSubMenu:Update()
	end
end

local function get_nearz() return 1.0 end
local function get_farz() return 16000.0 end

function gui.WIModelView:__init()
	gui.Base.__init(self)
	self.m_bRenderFilterEnabled = true
	self:SetClearColor(Color.Clear)
	self.m_matError = game.load_material("error")
	self.m_frameIndex = 0
end
function gui.WIModelView:SetClearColor(col)
	self.m_clearColor = col
	if(self.m_drawSceneInfo ~= nil) then self.m_drawSceneInfo.clearColor = self.m_clearColor end
end
local function draw_meshes(self,ent,meshes,shader,filter)
	local mdl = self:GetModel()
	for _,t in ipairs(meshes) do
		local mat = t[1]
		local meshGroupId = t[2]
		local meshGroup = t[3]
		local mesh = t[4]
		local subMesh = t[5]
		if(self.m_bRenderFilterEnabled == false or self.m_renderFilter(ent,mdl,meshGroupId,meshGroup,mesh,subMesh,mat) == true) then
			if(filter == nil or filter(ent,mdl,meshGroupId,meshGroup,mesh,subMesh,mat) == true) then
				if(shader.RecordBindMaterial ~= nil) then
          if(shader:RecordBindMaterial(mat) == false) then return false end
        end
				if(shader.BindVertexAnimationOffset ~= nil) then
					local vertAnimComponent = ent:GetComponent(ents.COMPONENT_VERTEX_ANIMATED)
					local vaBuffer = (vertAnimComponent ~= nil) and vertAnimComponent:GetVertexAnimationBuffer() or nil
					local bBindVertexAnimBuffer = false
					if(vaBuffer ~= nil) then
						local offset,animCount = vertAnimComponent:GetVertexAnimationBufferMeshOffset(subMesh)
						if(offset ~= nil) then
							local vaData = bit.bor(bit.rshift(bit.lshift(offset,16),16),bit.lshift(animCount,16))
							shader:BindVertexAnimationOffset(vaData)
							bBindVertexAnimBuffer = true
						end
					end
					if(bBindVertexAnimBuffer == false) then shader:BindVertexAnimationOffset(0) end
				end
				if(shader:RecordDrawMesh(subMesh) == false) then return false end
			end
		end
	end
  return true
end
function gui.WIModelView:GetScene() return self.m_scene end
function gui.WIModelView:GetRenderTarget() return self:GetScene():GetRenderer():GetRenderTarget() end
function gui.WIModelView:GetPresentationTexture() return self:GetScene():GetRenderer():GetPresentationTexture() end
function gui.WIModelView:GetRenderer() return self:GetScene():GetRenderer() end
function gui.WIModelView:SetRenderFilterEnabled(b) self.m_bRenderFilterEnabled = b end
function gui.WIModelView:SetRenderFilter(filter)
	if(filter == nil) then
		filter = function(ent,mdl,meshGroupId,meshGroup,mesh,subMesh,mat)
			return self.m_meshGroupIds[meshGroupId] == true
		end
	end
	self.m_renderFilter = filter
end
function gui.WIModelView:GetGroundModel()
	local modelName = "modelview_ground"
	local mdl = game.get_model(modelName)
	if(mdl ~= nil) then return mdl end
	mdl = game.create_model(modelName)
	mdl:SetMass(10.0)

	local subMesh = Model.Mesh.Sub.CreateQuad(util.metres_to_units(2))
	local mesh = Model.Mesh.Create()
	mesh:AddSubMesh(subMesh)
  
	mdl:AddMaterial(0,game.load_material("error"))
	subMesh:SetSkinTextureIndex(0)

	local meshGroup = mdl:GetMeshGroup(0)
	meshGroup:AddMesh(mesh)
	mdl:Update(Model.FUPDATE_ALL)
	return mdl
end
function gui.WIModelView:CreateGroundEntity()
	if(util.is_valid(self.m_entGround)) then return self.m_entGround end
	local entGround = ents.create("prop_dynamic")
	entGround:SetModel(self:GetGroundModel())
	entGround:Spawn()
	entGround:AddToScene(self.m_scene)
	entGround:RemoveFromScene(game.get_scene())
	self.m_entGround = entGround
	return entGround
end
function gui.WIModelView:SetGroundVisible(visible)
	self.m_groundVisible = visible
	if(visible == false) then
		if(util.is_valid(self.m_entGround) == false) then return end
		local renderC = self.m_entGround:GetComponent(ents.COMPONENT_RENDER)
		if(renderC ~= nil) then renderC:SetSceneRenderPass(game.SCENE_RENDER_PASS_NONE) end
		return
	end
	local entGround = self:CreateGroundEntity()
	local renderC = entGround:GetComponent(ents.COMPONENT_RENDER)
	if(renderC ~= nil) then renderC:SetSceneRenderPass(game.SCENE_RENDER_PASS_WORLD) end
end
function gui.WIModelView:GetLightSource() return self.m_entLight end
function gui.WIModelView:CreateLightSource()
	--[[if(util.is_valid(self.m_entLight)) then return end
	local ent = ents.create("env_light_spot")
	ent:SetKeyValue("spawnflags",tostring(1024))

	local colComponent = ent:GetComponent(ents.COMPONENT_COLOR)
	if(colComponent ~= nil) then colComponent:SetColor(light.color_temperature_to_color(3500)) end

	local radiusComponent = ent:GetComponent(ents.COMPONENT_RADIUS)
	if(radiusComponent ~= nil) then radiusComponent:SetRadius(300) end

	local lightC = ent:GetComponent(ents.COMPONENT_LIGHT)
	if(lightC ~= nil) then
		lightC:SetLightIntensity(20)
		lightC:SetShadowType(ents.LightComponent.SHADOW_TYPE_FULL)
		lightC:SetAddToGameScene(false)
		lightC:SetFalloffExponent(0.4)
	end

	local lightSpotC = ent:GetComponent(ents.COMPONENT_LIGHT_SPOT)
	if(lightSpotC ~= nil) then
		lightSpotC:SetInnerCutoffAngle(25)
		lightSpotC:SetOuterCutoffAngle(35)
	end
	ent:Spawn()

	ent:GetComponent(ents.COMPONENT_TOGGLE):TurnOn()
	self.m_scene:AddEntity(ent)
	self.m_entLight = ent]]
	if(util.is_valid(self.m_entLight)) then return end
	local entLight = ents.create("env_light_environment")
	entLight:SetKeyValue("spawnflags",tostring(1024))
	entLight:SetAngles(EulerAngles(65,210,0))
	entLight:Spawn()

	local colorC = entLight:GetComponent(ents.COMPONENT_COLOR)
	if(colorC ~= nil) then colorC:SetColor(light.color_temperature_to_color(light.get_average_color_temperature(light.NATURAL_LIGHT_TYPE_CLEAR_BLUESKY))) end

	local lightC = entLight:GetComponent(ents.COMPONENT_LIGHT)
	if(lightC ~= nil) then
		lightC:SetShadowType(ents.LightComponent.SHADOW_TYPE_FULL)
		lightC:SetLightIntensity(4)
	end
	local toggleC = entLight:GetComponent(ents.COMPONENT_TOGGLE)
	if(toggleC ~= nil) then toggleC:TurnOn() end

	entLight:AddToScene(self.m_scene)
	entLight:RemoveFromScene(game.get_scene())
	self.m_entLight = entLight
end
function gui.WIModelView:GetReflectionProbe() return self.m_entReflectionProbe end
function gui.WIModelView:CreateReflectionProbe()
	if(util.is_valid(self.m_entReflectionProbe)) then return end
	local entReflectionProbe = ents.create("env_reflection_probe")
	entReflectionProbe:SetKeyValue("ibl_material","pbr/ibl/venice_sunset")
	entReflectionProbe:SetKeyValue("ibl_strength","1.4")
	entReflectionProbe:Spawn()
	entReflectionProbe:AddToScene(self.m_scene)
	entReflectionProbe:RemoveFromScene(game.get_scene())
	self.m_entReflectionProbe = entReflectionProbe
end
function gui.WIModelView:SetFov(fov)
	if(util.is_valid(self.m_scene) == false) then return end
	local cam = self.m_scene:GetActiveCamera()
	cam:SetFOV(fov)
	cam:UpdateProjectionMatrix()
end
function gui.WIModelView:RenderEntity(shader,filter,drawCmd,cbBindShaderData)
	--[[shader = shader or self.m_shaderShaded
	if(util.is_valid(self.m_entity) == false or util.is_valid(shader) == false) then return end
	local mdlComponent = self.m_entity:GetComponent(ents.COMPONENT_MODEL)
	local mdl = (mdlComponent ~= nil) and mdlComponent:GetModel() or nil
	if(util.is_valid(mdl) == false) then return end

	drawCmd = drawCmd or game.get_draw_command_buffer()
	local scene = self.m_scene
	if(shader:RecordBeginDraw(drawCmd) == true) then
		if(shader.OnPrepareDraw ~= nil) then shader:OnPrepareDraw(drawCmd) end
    if(shader:RecordBindScene(scene:GetRenderer(),false) == true and shader:RecordBindEntity(self.m_entity) == true and (cbBindShaderData == nil or cbBindShaderData(shader,drawCmd) == true)) then
      draw_meshes(self,self.m_entity,self.m_meshes,shader,filter)
      draw_meshes(self,self.m_entity,self.m_meshesTranslucent,shader,filter)
      shader:RecordEndDraw()
    end
	end]]
end
function gui.WIModelView:SetShowMeshes(b) self.m_bShowMeshes = b end
function gui.WIModelView:ClearLightSources()
	for _,light in ipairs(self.m_lightSources) do
		if(light:IsValid() == true) then light:Remove() end
	end
	self.m_lightSources = {}
end
function gui.WIModelView:AddLightSource(light)
	table.insert(self.m_lightSources,light)
	self:UpdateSceneLights()
end
function gui.WIModelView:SetLightingEnabled(b)
	if(b == self:IsLightingEnabled()) then return end
	self.m_bLightingEnabled = b
	self:UpdateSceneLights()
	
	local worldEnv = self.m_scene:GetWorldEnvironment()
	worldEnv:SetUnlit(not b)
end
function gui.WIModelView:IsLightingEnabled() return self.m_bLightingEnabled end
function gui.WIModelView:UpdateSceneLights()
	local bEnabled = self:IsLightingEnabled()
	for _,light in ipairs(self.m_lightSources) do
		local pToggleComponent = light:GetEntity():GetComponent(ents.COMPONENT_TOGGLE)
		if(pToggleComponent ~= nil) then
			if(bEnabled == true) then pToggleComponent:TurnOn()
			else pToggleComponent:TurnOff() end
		end
	end
	self.m_scene:SetLightSources(self.m_lightSources)
end
function gui.WIModelView:OnInitialize()
	gui.Base.OnInitialize(self)
	self:EnableThinking()
	self.m_shaderShaded = shader.get("mde_textured")

	self:SetSize(64,64)

	self.m_lightSources = {}
	self.m_bLightingEnabled = false
	self.m_bShowMeshes = true
	self.m_lookAtPos = Vector()

	self.m_drawCmd = prosper.create_primary_command_buffer()
	self.m_actors = {}
	self.m_actorData = {}
	self:AddActor()

	self:SetMouseInputEnabled(true)
end
function gui.WIModelView:RemoveActor(i) util.remove(self:GetEntity(i)) end
function gui.WIModelView:AddActor()
	local ent = ents.create("mde_model")
	ent:AddComponent(ents.COMPONENT_FLEX)
	ent:AddComponent(ents.COMPONENT_VERTEX_ANIMATED)
	ent:AddComponent(ents.COMPONENT_EYE)
	ent:Spawn()

	local renderC = ent:GetComponent(ents.COMPONENT_RENDER)
	if(renderC ~= nil) then renderC:SetExemptFromOcclusionCulling(true) end

	ent:RemoveFromScene(game.get_scene())
	if(self.m_scene ~= nil) then ent:AddToScene(self.m_scene) end

	local i = #self.m_actors +1
	for j,ent in ipairs(self.m_actors) do
		if(ent:IsValid() == false) then
			i = j
			break
		end
	end
	self.m_actors[i] = ent
	self.m_actorData[#self.m_actors] = {}
	return ent,#self.m_actors
end
function gui.WIModelView:InitializeViewport(width,height)
	if(#self.m_actors == 0) then return end
	local gameScene = game.get_scene()
	local gameCam = gameScene:GetActiveCamera()
	width = width or gameScene:GetWidth()
	height = height or gameScene:GetHeight()
	local aspectRatio = width /height
	local fov,nearZ,farZ
	if(util.is_valid(gameCam)) then
		fov = gameCam:GetFOV()
		nearZ = gameCam:GetNearZ()
		farZ = gameCam:GetFarZ()
	else
		fov = ents.CameraComponent.DEFAULT_FOV
		nearZ = ents.CameraComponent.DEFAULT_NEAR_Z
		farZ = ents.CameraComponent.DEFAULT_FAR_Z
	end
	if(util.is_valid(self.m_scene)) then self.m_scene:GetEntity():Remove() end
	local createInfo = ents.SceneComponent.CreateInfo()
	createInfo.sampleCount = prosper.SAMPLE_COUNT_1_BIT
	self.m_scene = ents.create_scene(createInfo)
	if(self.m_scene == nil) then return end
	
	local entCam = ents.create("env_camera")
	entCam:RemoveFromAllScenes()
	entCam:AddToScene(self.m_scene)
	local cam = entCam:GetComponent(ents.COMPONENT_CAMERA)
	cam:SetAspectRatio(aspectRatio)
	cam:SetFOV(fov)
	cam:SetNearZ(nearZ)
	cam:SetFarZ(farZ)
	cam:UpdateMatrices()
	entCam:Spawn()

	local vc = entCam:AddComponent("viewer_camera")
	vc:Setup(width,height)
	local ent = self:GetEntity()
	if(util.is_valid(ent)) then vc:SetTarget(ent) end -- TODO: Take all entities into account

	self.m_scene:SetActiveCamera(cam)
	local entRenderer = ents.create("rasterization_renderer")
	local renderer = entRenderer:GetComponent(ents.COMPONENT_RENDERER)
	local rasterizer = entRenderer:GetComponent(ents.COMPONENT_RASTERIZATION_RENDERER)
	self.m_renderer = renderer
	self.m_scene:SetRenderer(renderer)

	self.m_scene:InitializeRenderTarget(width,height)
	self.m_scene:SetWorldEnvironment(gameScene:GetWorldEnvironment())
	rasterizer:GetRenderTarget():SetDebugName("WIModelView")
	rasterizer:SetPrepassMode(gameScene:GetRenderer():GetEntity():GetComponent(ents.COMPONENT_RASTERIZATION_RENDERER):GetPrepassMode())
	for _,ent in ipairs(self.m_actors) do
		if(ent:IsValid()) then
			ent:AddToScene(self.m_scene)
			ent:RemoveFromScene(game.get_scene())
		end
	end

	self:CreateLightSource()
	self:CreateReflectionProbe()

	self.m_cbPrepareRendering = game.add_callback("PrepareRendering",function(renderer)
		if(renderer ~= self.m_renderer) then return end
		self:PrepareMeshesForRendering(renderer)
	end)

	self.m_cam = cam
  
	self.m_drawSceneInfo = game.DrawSceneInfo()
	self.m_drawSceneInfo.clearColor = self.m_clearColor
	self.m_drawSceneInfo.renderFlags = game.RENDER_FLAG_ALL
	self.m_drawSceneInfo.scene = self.m_scene

	local pBg = gui.create("WIViewport",self)
	pBg:SetAutoAlignToParent(true)
	pBg:SetMovementControlsEnabled(false)
	self.m_pBg = pBg
	local bRender = false
	--[[self.m_cbPrepass = game.add_callback("RenderPrepass",function()
		if(bRender == false) then return end
		local renderer = self.m_scene:GetRenderer()
		local shader = renderer:GetPrepassShader()
		shader:RecordBindEntity(self.m_entity)
		draw_meshes(self,self.m_entity,self.m_meshes,shader)

		--shader:RecordBindEntity(self.m_entGround)
		--draw_meshes(self,self.m_entGround,,shader)
	end)]]
	self:UpdateCallbacks()
	self:SetCameraMovementEnabled(true)
end
function gui.WIModelView:OnVisibilityChanged(visible)
	self:UpdateCallbacks()
end
function gui.WIModelView:UpdateCallbacks()
	if(self:IsVisible() == false) then
		util.remove({self.m_cbRender,self.m_cbPreRender})
		return
	end
	if(util.is_valid(self.m_cbRender) == false) then
		self.m_cbRender = game.add_callback("Render",function()
			if(bRender == false) then return end
			-- if(self.m_bShowMeshes == true) then self:RenderEntity() end
			self:CallCallbacks("OnSceneRender",game.get_draw_command_buffer())
		end)
	end
		if(util.is_valid(self.m_cbPreRender) == false) then
		self.m_cbPreRender = game.add_callback("PreRenderScenes",function()
			if(self:IsValid() == false) then return end
			self:DrawScene()
		end)
	end
end
function gui.WIModelView:GetDrawSceneInfo() return self.m_drawSceneInfo end
function gui.WIModelView:DrawScene(immediate)
	if(#self.m_actors == 0 or util.is_valid(self.m_scene) == false) then return end
	-- if(self:GetModel() ~= nil) then _el = self print(self:GetModel():GetName()) end

	local cycleChanged = false
	for i,ent in ipairs(self.m_actors) do
		if(ent:IsValid()) then
			if(ent:HasComponent(ents.COMPONENT_PARTICLE_SYSTEM)) then cycleChanged = true
			else
				local animComponent = ent:GetComponent(ents.COMPONENT_ANIMATED)
				if(animComponent ~= nil) then
					local mdl = ent:GetModel()
					local anim = (mdl ~= nil) and mdl:GetAnimation(animComponent:GetAnimation()) or nil

					local nCycle = animComponent:GetCycle()

					local actorData = self.m_actorData[i]
					if(nCycle ~= actorData.lastCycle and ((anim ~= nil and anim:GetFrameCount() > 1) or actorData.lastCycle == nil)) then cycleChanged = true end
					actorData.lastCycle = nCycle
				end
			end
		end
	end

	if(self.m_alwaysRender ~= true and self.m_bRenderScheduled ~= true and cycleChanged == false) then return end
	self.m_bRenderScheduled = false
	local drawCmd = game.get_draw_command_buffer()
	if(self.m_updateCamera == true or self.m_alwaysRender) then
		self.m_updateCamera = false
		--self.m_scene:UpdateBuffers(drawCmd)
	end

	local rt = self.m_scene:GetRenderer():GetEntity():GetComponent(ents.COMPONENT_RASTERIZATION_RENDERER):GetRenderTarget()
	local img = rt:GetTexture():GetImage()
	--[[drawCmd:RecordImageBarrier(
		img,prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,prosper.PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT
	)]]

	self.m_frameIndex = self.m_frameIndex +1
	bRender = true
	--[[for _,ent in ipairs(self.m_actors) do
		if(ent:IsValid()) then
			local renderComponent = ent:GetComponent(ents.COMPONENT_RENDER)
			if(renderComponent ~= nil) then renderComponent:UpdateRenderBuffers(drawCmd,true) end
		end
	end

	local renderCGround = util.is_valid(self.m_entGround) and self.m_entGround:GetComponent(ents.COMPONENT_RENDER) or nil
	if(renderCGround ~= nil) then renderCGround:UpdateRenderBuffers(drawCmd,true) end]]

	if(immediate) then
		self.m_drawSceneInfo.commandBuffer = self.m_drawCmd
		self.m_drawCmd:StartRecording(true,false)
			game.render_scenes({self.m_drawSceneInfo})
		self.m_drawCmd:Flush()
	else
		-- self.m_drawSceneInfo.commandBuffer = nil
		game.queue_scene_for_rendering(self.m_drawSceneInfo)
	end
	
	bRender = false

	--[[drawCmd:RecordImageBarrier(
		img,prosper.PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT,prosper.ACCESS_SHADER_READ_BIT
	)]]
end
function gui.WIModelView:GetFrameIndex() return self.m_frameIndex end
function gui.WIModelView:ScheduleEntityForRendering(shader,ent,filter)
	if(ent == nil) then
		for _,ent in ipairs(self.m_actors) do
			if(ent:IsValid()) then self:ScheduleEntityForRendering(shader,ent,filter) end
		end
		return
	end
	local renderer = self.m_renderer
	local mdlC = util.is_valid(ent) and ent:GetComponent(ents.COMPONENT_MODEL) or nil
	local mdl = (mdlC ~= nil) and mdlC:GetModel() or nil
	if(mdl == nil) then return end
	local meshes = mdl:GetBodyGroupMeshes(0)
	for _,mesh in ipairs(meshes) do
		for _,subMesh in ipairs(mesh:GetSubMeshes()) do
			local matId = subMesh:GetSkinTextureIndex()
			local mat = mdlC:GetRenderMaterial(matId)
			if(mat ~= nil) then
				if(filter == nil or filter(ent,mdl,mesh,subMesh,mat) == true) then
					if(shader ~= nil) then renderer:ScheduleMeshForRendering(game.SCENE_RENDER_PASS_WORLD,shader,mat,ent,subMesh)
					else renderer:ScheduleMeshForRendering(game.SCENE_RENDER_PASS_WORLD,mat,ent,subMesh) end
				end
			end
		end
	end
end
function gui.WIModelView:PrepareMeshesForRendering(renderer)
	-- TODO: Take skin into account
	--if(self.m_bShowMeshes) then self:ScheduleEntityForRendering(nil,self.m_entity) end
	--if(self.m_groundVisible) then self:ScheduleEntityForRendering(nil,self.m_entGround) end

	self:CallCallbacks("PrepareRendering")
end
function gui.WIModelView:OnRemove()
	gui.Base.OnRemove(self)
	self:ClearScene()
	util.remove(self.m_cbPrepareRendering)
	util.remove(self.m_cbPrepass)
	util.remove(self.m_cbRender)
	util.remove(self.m_cbPreRender)
	if(util.is_valid(self.m_renderer)) then self.m_renderer:GetEntity():Remove() end

	for _,ent in ipairs(self.m_actors) do util.remove(ent) end

	util.remove(self.m_entGround)
	util.remove(self.m_entLight)
	util.remove(self.m_entReflectionProbe)
	if(util.is_valid(self.m_cam)) then self.m_cam:GetEntity():Remove() end
end
function gui.WIModelView:ClearScene()
	if(util.is_valid(self.m_scene)) then self.m_scene:GetEntity():Remove() end
	if(util.is_valid(self.m_renderer)) then self.m_renderer:GetEntity():Remove() end
	self.m_renderer = nil
	util.remove(self.m_cbPrepareRendering)
end
function gui.WIModelView:GetCamera() return self.m_cam end
function gui.WIModelView:GetViewerCamera()
	local cam = self:GetCamera()
	return util.is_valid(cam) and cam:GetEntity():GetComponent("viewer_camera") or nil
end
function gui.WIModelView:GetZoom()
	local vc = self:GetViewerCamera()
	if(vc == nil) then return 0.0 end
	return vc:GetZoom()
end
function gui.WIModelView:SetZoom(zoom)
	local vc = self:GetViewerCamera()
	if(vc == nil) then return end
	return vc:SetZoom(zoom)
end
function gui.WIModelView:GetModel(actorIdx)
	actorIdx = actorIdx or 1
	local ent = self.m_actors[actorIdx]
	if(util.is_valid(ent) == false) then return end
	local mdlComponent = ent:GetComponent(ents.COMPONENT_MODEL)
	if(mdlComponent == nil) then return end
	return mdlComponent:GetModel()
end
function gui.WIModelView:GetParticleSystemName() return self.m_ptSystemName end
function gui.WIModelView:UpdateModel()
	self.m_bRenderScheduled = true
	--self.m_meshes = {}
	--self.m_meshesTranslucent = {}
	self.m_meshGroupIds = {}

	--local mdlComponent = util.is_valid(self.m_entity) and self.m_entity:GetComponent(ents.COMPONENT_MODEL) or nil
	--local mdl = (mdlComponent ~= nil) and mdlComponent:GetModel() or nil
	--if(mdl ~= nil) then self.m_meshes = mdl:GetBodyGroupMeshes(0) end

	self:FitCameraToScene()
end
function gui.WIModelView:FitCameraToScene(min,max)
	local vc = self:GetViewerCamera()
	if(vc ~= nil) then
		vc:FitViewToScene(min,max)
	end
end
function gui.WIModelView:SetParticleSystem(ptSystem)
	self.m_ptSystemName = ptSystem
	local ent = self:GetEntity()
	if(util.is_valid(ent) == false) then return end
	ent:RemoveComponent(ents.COMPONENT_RENDER)
	local ptC = ent:AddComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	if(ptC == nil) then return end
	ent:SetKeyValue("loop","1")
	if(ptSystem == nil) then return end
	ptC:InitializeFromParticleSystemDefinition(ptSystem)
	local toggleC = ent:GetComponent(ents.COMPONENT_TOGGLE)
	if(toggleC ~= nil) then toggleC:TurnOn() end
	self:UpdateModel()
	return ptC
end
function gui.WIModelView:ApplyModelFromEntity(entSrc,actorIdx)
	local mdl = entSrc:GetModel()
	local entDst = self:GetEntity(actorIdx)
	if(mdl == nil or util.is_valid(entDst) == false or self:SetModel(mdl,actorIdx) == false) then return false end

	local function copy_component(type)
		local cSrc = entSrc:GetComponent(type)
		local cDst = entDst:AddComponent(type)
		if(cSrc == nil or cDst == nil) then return end
		cSrc:Copy(cDst)
	end
	copy_component(ents.COMPONENT_MODEL)
	copy_component(ents.COMPONENT_RENDER)
	copy_component(ents.COMPONENT_ANIMATED)
	copy_component(ents.COMPONENT_VERTEX_ANIMATED)
	copy_component(ents.COMPONENT_FLEX)

	if(entSrc:HasComponent(ents.COMPONENT_EYE)) then entDst:AddComponent(ents.COMPONENT_EYE) end
	return true
end
function gui.WIModelView:SetModel(mdl,actorIdx)
	if(mdl ~= nil and type(mdl) == "string") then
		mdl = game.load_model(mdl)
		if(mdl ~= nil) then return self:SetModel(mdl,actorIdx) end
		return false
	end
	self.m_ptSystemName = nil
	--self.m_meshes = {}
	--self.m_meshesTranslucent = {}
	local ent = self:GetEntity(actorIdx)
	if(util.is_valid(ent) == false) then return false end
	ent:RemoveComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	ent:AddComponent(ents.COMPONENT_RENDER)
	local bValid = util.is_valid(mdl)
	local pMdlComponent = ent:GetComponent(ents.COMPONENT_MODEL)
	if(pMdlComponent ~= nil) then
		if(bValid == false) then pMdlComponent:SetModel()
		else pMdlComponent:SetModel(mdl) end
	end
	self.m_bRenderScheduled = true
	if(bValid == false) then return false end
	self:UpdateModel()
	return true
end
function gui.WIModelView:SetRotationModeEnabled(enabled)
	if(enabled) then
		self.m_bRotate = true
		self.m_tLastCursorPos = self:GetCursorPos()
		return
	end
	self.m_bRotate = false
end
function gui.WIModelView:SetPanningModeEnabled(enabled)
	if(enabled) then
		self.m_bMove = true
		self.m_tLastCursorPos = self:GetCursorPos()
		self.m_panningStartPos = self:GetCursorPos()
		return
	end
	self.m_bMove = false
end
function gui.WIModelView:OnThink()
	gui.Base.OnThink(self)
	if(self.m_cursorTracker ~= nil) then
		self.m_cursorTracker:Update()
		if(self.m_cursorTracker:HasExceededMoveThreshold(2)) then
			self.m_cursorTracker = nil
			self:SetPanningModeEnabled(true)
		end
	end
	if(self.m_bRotate ~= true and self.m_bMove ~= true) then return end
	local cursorPos = self:GetCursorPos()
	local offset = cursorPos -self.m_tLastCursorPos
	if(self.m_bRotate == true) then
		local vc = self:GetViewerCamera()
		if(vc ~= nil) then
			vc:Rotate(offset.x,offset.y)
			self.m_updateCamera = true
			self.m_bRenderScheduled = true
		end
	end
	if(self.m_bMove == true) then
		local vc = self:GetViewerCamera()
		if(vc ~= nil) then
			local speed = 30.0
			vc:Pan(offset.x *speed,offset.y *speed)
			self.m_updateCamera = true
			self.m_bRenderScheduled = true
		end
	end
	self.m_tLastCursorPos = cursorPos
end
function gui.WIModelView:MouseCallback(button,action,mods)
	gui.Base.MouseCallback(self,button,action,mods)
	if(button == input.MOUSE_BUTTON_LEFT) then
		local handled,entActor,hitPos,startPos,hitData = ents.ClickComponent.inject_click_input(input.ACTION_ATTACK,action == input.STATE_PRESS)
		if(handled == util.EVENT_REPLY_HANDLED) then return util.EVENT_REPLY_HANDLED end
	end
	--if(handled == util.EVENT_REPLY_UNHANDLED and util.is_valid(entActor)) then
	if(button == input.MOUSE_BUTTON_RIGHT) then
		if(action == input.STATE_PRESS) then
			self.m_leftMouseInput = true
			self.m_cursorTracker = gui.CursorTracker()
			self:EnableThinking()
		else
			if(self.m_cursorTracker ~= nil) then
				self.m_cursorTracker = nil

				if(self.m_bMove and (self:GetCursorPos() -self.m_panningStartPos):LengthSqr() > 0.1) then return util.EVENT_REPLY_UNHANDLED end
				self:SetPanningModeEnabled(false)

				local ent = self:GetEntity()
				local mdl = util.is_valid(ent) and ent:GetModel() or nil
				if(mdl ~= nil) then
					local anims = mdl:GetAnimationNames()
					local pContext = gui.open_context_menu()
					if(util.is_valid(pContext) == false) then return end

					gui.WIModelView.add_default_actor_context_options(pContext,ent,function() self:Render() end)
					if(#anims > 1) then
						table.sort(anims)
						local pItem,pSubMenu = pContext:AddSubMenu(locale.get_text("animation"))
						for _,animName in ipairs(anims) do
							local anim = mdl:GetAnimation(animName)
							if(anim ~= nil and bit.band(anim:GetFlags(),game.Model.Animation.FLAG_GESTURE) == 0) then
								local pItem = pSubMenu:AddItem(animName,function(pItem)
									if(util.is_valid(ent) == false) then return end
									ent:PlayAnimation(animName)
									self:Render()
									self.m_curAnim = nil
								end)
								pItem:AddCallback("OnSelectionChanged",function(pItem,selected)
									if(util.is_valid(ent) == false) then return end
									if(selected) then
										self.m_curAnim = self.m_curAnim or ent:GetAnimation()
										ent:PlayAnimation(animName)
										self:Render()
										return
									end
									if(self.m_curAnim == nil or pSubMenu:GetSelectedItem() ~= nil) then return end
									ent:PlayAnimation(self.m_curAnim)
									self:Render()
									self.m_curAnim = nil
								end)
							end
						end
						pSubMenu:Update()
					end

					local flexAnims = mdl:GetFlexAnimationNames()
					if(#flexAnims > 0) then
						table.sort(flexAnims)
						local pItem,pSubMenu = pContext:AddSubMenu(locale.get_text("flex_animation"))
						pSubMenu:AddItem(locale.get_text("none"),function(pItem)
							if(util.is_valid(ent) == false) then return end
							local flexC = ent:GetComponent(ents.COMPONENT_FLEX)
							if(flexC ~= nil) then
								for _,animId in ipairs(flexC:GetFlexAnimations()) do
									flexC:StopFlexAnimation(animId)
								end
								for i=1,mdl:GetFlexControllerCount() do
									flexC:SetFlexController(i -1,0.0)
								end
							end
							self:Render()
						end)
						for _,animName in ipairs(flexAnims) do
							local anim = mdl:GetFlexAnimation(mdl:LookupFlexAnimation(animName))
							if(anim ~= nil) then
								local pItem = pSubMenu:AddItem(animName,function(pItem)
									if(util.is_valid(ent) == false) then return end
									local flexC = ent:GetComponent(ents.COMPONENT_FLEX)
									if(flexC ~= nil) then flexC:PlayFlexAnimation(animName) end
									self:Render()
								end)
								pItem:AddCallback("OnSelectionChanged",function(pItem,selected)
									if(util.is_valid(ent) == false) then return end
									if(selected) then
										local flexC = ent:GetComponent(ents.COMPONENT_FLEX)
										if(flexC ~= nil) then flexC:PlayFlexAnimation(animName) end
										self:Render()
										return
									end
									if(pSubMenu:GetSelectedItem() ~= nil) then return end
									local flexC = ent:GetComponent(ents.COMPONENT_FLEX)
									if(flexC ~= nil) then
										for _,animId in ipairs(flexC:GetFlexAnimations()) do
											flexC:StopFlexAnimation(animId)
										end
										for i=1,mdl:GetFlexControllerCount() do
											flexC:SetFlexController(i -1,0.0)
										end
									end
									self:Render()
								end)
							end
						end
						pSubMenu:Update()
					end

					pContext:Update()
					if(pContext:GetItemCount() == 0) then gui.close_context_menu() end
					return util.EVENT_REPLY_HANDLED
				end
			else
				self:SetPanningModeEnabled(false)
			end
		end
		return util.EVENT_REPLY_HANDLED
	end

	if(self.m_bCameraMovementEnabled) then
		if(button == input.MOUSE_BUTTON_LEFT) then
			self:SetRotationModeEnabled(action == input.STATE_PRESS)
			return util.EVENT_REPLY_HANDLED
		end
		return
	end
end
function gui.WIModelView:ScrollCallback(xoffset,yoffset)
	gui.Base.ScrollCallback(self,xoffset,yoffset)
	if(self.m_bCameraMovementEnabled == false) then return end
	local vc = self:GetViewerCamera()
	if(vc ~= nil) then
		vc:SetZoom(vc:GetZoom() -yoffset *10.0)
		self.m_updateCamera = true
		self.m_bRenderScheduled = true
	end


	--[[local posCam = self:GetCameraPosition()
	local posLookAt = self:GetLookAtPosition()
	local dir = posLookAt -posCam
	local l = dir:Length()
	if(l == 0.0) then return end
	yoffset = yoffset *20.0
	dir = dir /l
	posCam = posCam +dir *math.min(math.max(l -1.0,1.0),math.abs(yoffset)) *math.sign(yoffset)]]
end
function gui.WIModelView:SetCameraMovementEnabled(b)
	self.m_bCameraMovementEnabled = b
	self:SetMouseInputEnabled(b)
	self:SetScrollInputEnabled(b)
end
function gui.WIModelView:GetCameraPosition() return self.m_cam:GetEntity():GetPos() end
function gui.WIModelView:SetCameraPosition(pos) self.m_cam:GetEntity():SetPos(pos) end
function gui.WIModelView:SetCameraRotation(rot) self.m_cam:GetEntity():SetRotation(rot) end
function gui.WIModelView:GetLookAtTarget()
	local vc = self:GetViewerCamera()
	if(vc == nil) then return Vector() end
	return vc:GetLookAtTarget()
end
function gui.WIModelView:SetLookAtTarget(t)
	local vc = self:GetViewerCamera()
	if(vc == nil) then return end
	return vc:SetLookAtTarget(t)
end
function gui.WIModelView:GetRotation()
	local vc = self:GetViewerCamera()
	if(vc == nil) then return 0.0,0.0 end
	return vc:GetRotation()
end
function gui.WIModelView:SetRotation(xRot,yRot)
	local vc = self:GetViewerCamera()
	if(vc == nil) then return end
	return vc:SetRotation(xRot,yRot)
end
function gui.WIModelView:OnUpdate()
	if(util.is_valid(self.m_pBg) == false or util.is_valid(self.m_scene) == false) then return end
	local size = self:GetSize()
	if(size.x == 0 or size.y == 0) then
		self.m_cam:SetAspectRatio(1.0)
		self.m_cam:UpdateProjectionMatrix()
		return
	end
	self.m_cam:SetAspectRatio(size.x /size.y)
	self.m_cam:UpdateProjectionMatrix()

	self.m_pBg:SetScene(self.m_scene,self.m_scene:GetRenderer(),false)

	-- self:UpdateModel()
	self:Render()
end
function gui.WIModelView:SetAlwaysRender(alwaysRender) self.m_alwaysRender = alwaysRender end
function gui.WIModelView:Render()
	self.m_bRenderScheduled = true
	self.m_updateCamera = true
end
function gui.WIModelView:OnSizeChanged(w,h)
	gui.Base.OnSizeChanged(self,w,h)
	self:Update()
end
function gui.WIModelView:GetEntity(actorIdx)
	actorIdx = actorIdx or 1
	return self.m_actors[actorIdx]
end
function gui.WIModelView:PlayAnimation(anim,actorIdx)
	local ent = self:GetEntity(actorIdx)
	if(util.is_valid(ent) == false) then return end
	local animComponent = ent:GetComponent(ents.COMPONENT_ANIMATED)
	if(animComponent == nil) then return end
	animComponent:PlayAnimation(anim)
	self.m_actorData[actorIdx or 1].lastCycle = nil
end
function gui.WIModelView:PlayIdleAnimation()
	local model = self:GetModel()
	if(model == nil) then return end
	local anim = model:SelectWeightedAnimation(game.Model.Animation.ACT_IDLE)
	if(anim == -1) then anim = model:LookupAnimation("idle") end
	if(anim == -1) then
		local r = string.find_similar_elements("idle",model:GetAnimationNames(),1)
		anim = r[1] or -1
	end
	if(anim == -1) then anim = model:LookupAnimation("ragdoll") end
	if(anim ~= -1) then
		self:PlayAnimation(anim)
	end
end
function gui.WIModelView.create(width,height,defaultModel,parent)
	local modelView = gui.create("WIModelView",parent)
	modelView:SetSize(width,height)
	modelView:InitializeViewport(width,height)
	modelView:SetFov(math.horizontal_fov_to_vertical_fov(45.0,width,height))
	modelView:RequestFocus()
	modelView:TrapFocus()
	modelView:SetCameraMovementEnabled(false)
	if(defaultModel ~= nil) then
		modelView:SetModel(defaultModel)
		modelView:PlayIdleAnimation()
	end
	modelView:ScheduleUpdate()
	return modelView
end
gui.register("WIModelView",gui.WIModelView)
