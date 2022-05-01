--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local function base_get_bodygroup_data(mdl,bgId,bgVal,skin)
	local mgId = mdl:GetBodyGroupMesh(bgId,bgVal)
	if(mgId == nil) then return end
	local meshGroup = mdl:GetMeshGroup(mgId)
	local dbgVerts = {}
	local min,max
	local materialIndices = {}
	local nVerts = 0
	for _,mesh in ipairs(meshGroup:GetMeshes()) do
		for _,subMesh in ipairs(mesh:GetSubMeshes()) do
			local verts = subMesh:GetVertices()
			local tris = subMesh:GetIndices()
			local matIdx = mdl:GetMaterialIndex(subMesh,skin)
			if(matIdx ~= nil) then materialIndices[matIdx] = true end
			nVerts = nVerts +#verts
		end

		min = min or Vector(math.huge,math.huge,math.huge)
		max = max or -min
		local minMesh,maxMesh = mesh:GetBounds()
		for i=0,2 do
			if(minMesh:Get(i) < min:Get(i)) then min:Set(i,minMesh:Get(i)) end
			if(maxMesh:Get(i) > max:Get(i)) then max:Set(i,maxMesh:Get(i)) end
		end
	end
	return materialIndices,min or Vector(),max or Vector()
end

local function get_bodygroup_data(mdl,bgId,bgVal,skin)
	local materialIndices,min,max = base_get_bodygroup_data(mdl,bgId,bgVal,skin)
	local function is_valid(materialIndices,min,max)
		return materialIndices ~= nil and table.is_empty(materialIndices) == false and min:DistanceSqr(max) > 0.001
	end
	if(is_valid(materialIndices,min,max)) then return materialIndices,min,max,true end

	-- Unable to determine bounds for bodygroup; Try other configurations
	if(bgVal ~= 0) then
		local materialIndices,min,max = base_get_bodygroup_data(mdl,bgId,0,skin)
		if(is_valid(materialIndices,min,max)) then return materialIndices,min,max,false end
	end
	if(bgVal == 1) then return materialIndices,min,max,false end
	materialIndices,min,max = base_get_bodygroup_data(mdl,bgId,1,skin)
	return materialIndices,min,max,false
end

local function create_translucent_material(mat)
	local matCopy = mat:Copy()
	local db = matCopy:GetDataBlock()
	-- db:SetValue("int","alpha_mode",tostring(game.Material.ALPHA_MODE_BLEND))
	-- db:SetValue("float","alpha_factor","0.4")
	
	db:SetValue("vector","color_factor","0.05 0.05 0.05")
	matCopy:SetShader("unlit")
	return matCopy
end

local function make_non_bodygroup_materials_translucent(mdlC,materialIndices)
	local mdl = mdlC:GetModel()
	if(mdl == nil) then return end
	for idx,mat in ipairs(mdl:GetMaterials()) do
		if(materialIndices[idx -1] ~= true) then
			mdlC:SetMaterialOverride(idx -1,create_translucent_material(mat))
		end
	end
end

function gui.WIModelView:SetBodyPart(bgId,bgVal)
	local ent = self:GetEntity()
	local mdl = ent:GetModel()
	local materialIndices,min,max,native = get_bodygroup_data(mdl,bgId,bgVal,ent:GetSkin())
	local extents = (min ~= nil) and min:DistanceSqr(max) or 0.0
	local extentsVisible = extents > 0.0001
	if(materialIndices ~= nil and extentsVisible == false) then
		local mdl = ent:GetModel()
		local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
		if(mdl ~= nil and mdlC ~= nil) then
			if(native) then
				for i,mat in ipairs(mdl:GetMaterials()) do
					mdlC:SetMaterialOverride(i -1,create_translucent_material(mat))
				end
			end
		end
		-- self:SetCrossedOut(true)
	else
		if(materialIndices ~= nil) then
			if(min:DistanceSqr(max) > 0.0001) then
				if(native) then make_non_bodygroup_materials_translucent(ent:GetComponent(ents.COMPONENT_MODEL),materialIndices) end

				local viewerCam = self:GetViewerCamera()
				if(util.is_valid(viewerCam)) then
					viewerCam:FitViewToScene(min,max)
				end
			end
		end

		local mdlC = util.is_valid(ent) and ent:GetComponent(ents.COMPONENT_MODEL) or nil
		if(mdlC ~= nil) then
			if(bgId ~= -1) then mdlC:SetBodyGroup(bgId,bgVal) end
		end
	end
end

