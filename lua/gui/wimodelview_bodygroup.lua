-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local function base_get_bodygroup_data(mdl, bgId, bgVal, skin)
	local mgId = mdl:GetBodyGroupMesh(bgId, bgVal)
	if mgId == nil then
		return
	end
	local meshGroup = mdl:GetMeshGroup(mgId)
	local min, max
	local materialIndices = {}
	local subMeshes = {}
	for meshIdx, mesh in ipairs(meshGroup:GetMeshes()) do
		for subMeshIdx, subMesh in ipairs(mesh:GetSubMeshes()) do
			local matIdx = mdl:GetMaterialIndex(subMesh, skin)
			if matIdx ~= nil then
				materialIndices[matIdx] = true
				table.insert(subMeshes, {
					meshGroupIdx = mgId,
					meshIdx = meshIdx - 1,
					subMeshIdx = subMeshIdx - 1,
				})
			end
		end

		min = min or Vector(math.huge, math.huge, math.huge)
		max = max or -min
		local minMesh, maxMesh = mesh:GetBounds()
		for i = 0, 2 do
			if minMesh:Get(i) < min:Get(i) then
				min:Set(i, minMesh:Get(i))
			end
			if maxMesh:Get(i) > max:Get(i) then
				max:Set(i, maxMesh:Get(i))
			end
		end
	end
	return materialIndices, min or Vector(), max or Vector(), subMeshes
end

local function get_bodygroup_data(mdl, bgId, bgVal, skin)
	local materialIndices, min, max, subMeshIndexData = base_get_bodygroup_data(mdl, bgId, bgVal, skin)
	local function is_valid(materialIndices, min, max)
		return materialIndices ~= nil and table.is_empty(materialIndices) == false and min:DistanceSqr(max) > 0.001
	end
	if is_valid(materialIndices, min, max) then
		return materialIndices, min, max, true, subMeshIndexData
	end

	-- Unable to determine bounds for bodygroup; Try other configurations
	if bgVal ~= 0 then
		local materialIndices2, min, max, subMeshIndexData = base_get_bodygroup_data(mdl, bgId, 0, skin)
		if is_valid(materialIndices2, min, max) then
			return materialIndices or materialIndices2, min, max, false, subMeshIndexData
		end
	end
	if bgVal == 1 then
		return materialIndices, min, max, false, subMeshIndexData
	end
	local materialIndices2
	materialIndices2, min, max, subMeshIndexData = base_get_bodygroup_data(mdl, bgId, 1, skin)
	return materialIndices2 or materialIndices, min, max, false, subMeshIndexData
end

-- Generate a copy of the model where all meshes except the specified ones are blacked out
local function generate_model_copy_with_blacked_out_parts(mdl, meshIndices)
	local matBlack = game.load_material("black_unlit")
	local cpy = mdl:Copy(game.Model.FCOPY_BIT_MESHES)
	local matIdx, skinMatIdx = cpy:AddMaterial(0, matBlack)
	local meshIdxMap = {}
	for _, indexData in ipairs(meshIndices) do
		meshIdxMap[indexData.meshGroupIdx] = meshIdxMap[indexData.meshGroupIdx] or {}
		meshIdxMap[indexData.meshGroupIdx][indexData.meshIdx] = meshIdxMap[indexData.meshGroupIdx][indexData.meshIdx]
			or {}
		meshIdxMap[indexData.meshGroupIdx][indexData.meshIdx][indexData.subMeshIdx] = true
	end
	for mgIdx, meshGroup in ipairs(cpy:GetMeshGroups()) do
		for mIdx, mesh in ipairs(meshGroup:GetMeshes()) do
			for smIdx, subMesh in ipairs(mesh:GetSubMeshes()) do
				if
					meshIdxMap[mgIdx - 1] == nil
					or meshIdxMap[mgIdx - 1][mIdx - 1] == nil
					or meshIdxMap[mgIdx - 1][mIdx - 1][smIdx - 1] ~= true
				then
					subMesh:SetSkinTextureIndex(skinMatIdx)
				end
			end
		end
	end
	return cpy
end

function gui.WIModelView:SetBodyPart(bgId, bgVal)
	local ent = self:GetEntity()
	local mdl = ent:GetModel()
	local materialIndices, min, max, native, subMeshIndexData = get_bodygroup_data(mdl, bgId, bgVal, ent:GetSkin())
	local mdlCpy = generate_model_copy_with_blacked_out_parts(mdl, subMeshIndexData)
	ent:SetModel(mdlCpy)
	if materialIndices ~= nil then
		if min:DistanceSqr(max) > 0.0001 then
			local viewerCam = self:GetViewerCamera()
			if util.is_valid(viewerCam) then
				viewerCam:FitViewToScene(min, max)
			end
		end
	end

	local mdlC = util.is_valid(ent) and ent:GetComponent(ents.COMPONENT_MODEL) or nil
	if mdlC ~= nil then
		if bgId ~= -1 then
			mdlC:SetBodyGroup(bgId, bgVal)
		end
	end
end
