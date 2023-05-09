include("/shaders/mde/mde_skeleton_depth.lua")

util.register_class("gui.WIModelEditorHitboxes", gui.Base, gui.WIModelEditorPanel)

local MARGIN_OFFSET = 20

function gui.WIModelEditorHitboxes:__init()
	gui.Base.__init(self)
	gui.WIModelEditorPanel.__init(self)
end
function gui.WIModelEditorHitboxes:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_tHitboxOffset = { {}, {} }
	self.m_shader = shader.get("mde_skeleton_depth")
	self.m_shaderFlat = shader.get("mde_flat")

	local pHitboxes = gui.create("WITable", self)
	pHitboxes:SetAutoAlignToParent(true)
	pHitboxes:SetScrollable(true)
	pHitboxes:SetSelectableMode(gui.Table.SELECTABLE_MODE_SINGLE)
	pHitboxes:SetRowHeight(20)
	local pHeader = pHitboxes:AddHeaderRow()
	pHeader:SetValue(0, locale.get_text("id"))
	pHeader:SetValue(1, locale.get_text("bone"))
	pHeader:SetValue(2, locale.get_text("hitgroup"))
	pHeader:SetValue(3, locale.get_text("min"))
	pHeader:SetValue(4, locale.get_text("max"))
	self.m_pHitboxes = pHitboxes
end
function gui.WIModelEditorHitboxes:SetModel(mdl)
	local ent = self:GetEntity()
	local pEditor = self:GetEditor()
	local pHitboxes = self.m_pHitboxes
	if util.is_valid(pHitboxes) == false then
		return
	end
	pHitboxes:Clear()
	if
		util.is_valid(mdl) == false
		or self.m_shader == nil
		or util.is_valid(ent) == false
		or util.is_valid(pEditor) == false
	then
		return
	end
	local mdlComponent = ent:GetComponent(ents.COMPONENT_MODEL)
	local mdl = (mdlComponent ~= nil) and mdlComponent:GetModel() or nil
	if util.is_valid(mdl) == false then
		return
	end
	local skeleton = mdl:GetSkeleton()
	local refPose = mdl:GetReferencePose()
	local dsVerts = util.DataStream()
	local dsIndices = util.DataStream()

	local dsFlatVerts = util.DataStream()
	local dsFlatIndices = util.DataStream()
	local boxMesh = Model.Mesh.Sub.create_box(game.Model.BoxCreateInfo(Vector(-1, -1, -1), Vector(1, 1, 1))) -- TODO: Don't create buffers!
	local boxVerts = boxMesh:GetVertices()
	local boxTriangles = boxMesh:GetIndices()

	local hitboxBones = mdl:GetHitboxBones()
	local boxOutlineVerts = pEditor:GetBoxVertices()
	self.m_vertCountOutline = #boxOutlineVerts
	self.m_vertCount = #boxTriangles
	self.m_tHitboxOffset = { {}, {} }
	for hitboxId, boneId in ipairs(hitboxBones) do
		local min, max = mdl:GetHitboxBounds(boneId)
		local hitGroup = mdl:GetHitboxGroup(boneId)
		local center = (min + max) / 2.0
		local bounds = (max - min) / 2.0

		local col = Color.White
		local hitGroupName = locale.get_text("unknown") .. " (" .. hitGroup .. ")"
		if hitGroup == game.HITGROUP_HEAD then
			col = Color.Red
			hitGroupName = locale.get_text("head")
		elseif hitGroup == game.HITGROUP_CHEST then
			col = Color.Lime
			hitGroupName = locale.get_text("chest")
		elseif hitGroup == game.HITGROUP_STOMACH then
			col = Color.Blue
			hitGroupName = locale.get_text("stomach")
		elseif hitGroup == game.HITGROUP_LEFT_ARM then
			col = Color.Yellow
			hitGroupName = locale.get_text("left_arm")
		elseif hitGroup == game.HITGROUP_RIGHT_ARM then
			col = Color.Cyan
			hitGroupName = locale.get_text("right_arm")
		elseif hitGroup == game.HITGROUP_LEFT_LEG then
			col = Color.Magenta
			hitGroupName = locale.get_text("left_leg")
		elseif hitGroup == game.HITGROUP_RIGHT_LEG then
			col = Color.OrangeRed
			hitGroupName = locale.get_text("right_leg")
		elseif hitGroup == game.HITGROUP_GEAR then
			col = Color.SpringGreen
			hitGroupName = locale.get_text("gear")
		end
		col = col:ToVector4()

		local bone = skeleton:GetBone(boneId)
		local pRow = pHitboxes:AddRow()
		pRow:SetValue(0, tostring(hitboxId - 1))
		pRow:SetValue(1, bone:GetName())
		pRow:SetValue(2, hitGroupName)
		pRow:SetValue(3, tostring(min))
		pRow:SetValue(4, tostring(max))
		pRow:AddCallback("OnSelected", function(pRow)
			if self:IsValid() == false then
				return
			end
			self:GetEditor():ScheduleEntityForRendering()
			local selectedHitbox = tonumber(pRow:GetValue(0))
			self.m_selectedHitbox = selectedHitbox
		end)

		self.m_tHitboxOffset[1][hitboxId - 1] = dsFlatIndices:Tell() / util.SIZEOF_INT
		self.m_tHitboxOffset[2][hitboxId - 1] = dsIndices:Tell() / util.SIZEOF_INT
		local pos, rot = refPose:GetBoneTransform(boneId)
		rot = rot:GetInverse()
		for _, v in ipairs(boxOutlineVerts) do
			v = Vector(v.x * bounds.x, v.y * bounds.y, v.z * bounds.z) + center
			v = v * rot
			dsVerts:WriteVector(pos + v)
			dsVerts:WriteVector4(col)

			dsIndices:WriteUInt32(boneId)
		end
		col.w = 0.5
		for _, vId in ipairs(boxTriangles) do
			local v = boxVerts[vId + 1]
			v = Vector(v.x * bounds.x, v.y * bounds.y, v.z * bounds.z) + center
			v = v * rot
			dsFlatVerts:WriteVector(pos + v)
			dsFlatVerts:WriteVector4(col)

			dsFlatIndices:WriteUInt32(boneId)
		end
	end

	local bufCreateInfo = prosper.BufferCreateInfo()
	bufCreateInfo.size = dsVerts:GetSize()
	bufCreateInfo.usageFlags = prosper.BUFFER_USAGE_VERTEX_BUFFER_BIT
	bufCreateInfo.memoryFeatures = prosper.MEMORY_FEATURE_GPU_BULK_BIT

	local bufVerts = prosper.create_buffer(bufCreateInfo, dsVerts)
	if bufVerts == nil then
		return
	end
	bufVerts:SetDebugName("mdlviewer_hitbox_verts")
	bufCreateInfo.size = dsIndices:GetSize()
	local bufBoneIndices = prosper.create_buffer(bufCreateInfo, dsIndices)
	if bufBoneIndices == nil then
		return
	end
	bufBoneIndices:SetDebugName("mdlviewer_hitbox_indices")

	self.m_bufHitboxVerts = bufVerts
	self.m_bufHitboxBoneIndices = bufBoneIndices

	bufCreateInfo.size = dsFlatVerts:GetSize()
	local bufFlatVerts = prosper.create_buffer(bufCreateInfo, dsFlatVerts)
	if bufFlatVerts == nil then
		return
	end
	bufFlatVerts:SetDebugName("mdlviewer_hitbox_flat_verts")
	bufCreateInfo.size = dsFlatIndices:GetSize()
	local bufFlatBoneIndices = prosper.create_buffer(bufCreateInfo, dsFlatIndices)
	if bufFlatBoneIndices == nil then
		return
	end
	bufFlatBoneIndices:SetDebugName("mdlviewer_hitbox_flat_indices")

	self.m_bufFlatVerts = bufFlatVerts
	self.m_bufFlatBoneIndices = bufFlatBoneIndices
end

function gui.WIModelEditorHitboxes:Render(drawCmd, cam)
	local ent = self:GetEntity()
	if self:GetShowItems() == false or self.m_shader == nil or util.is_valid(ent) == false then
		return
	end
	local offset
	local offsetOutline
	local vertCount
	local vertCountOutline
	if
		self:IsSelected() == true
		and self.m_selectedHitbox ~= nil
		and self.m_tHitboxOffset[1][self.m_selectedHitbox] ~= nil
	then
		offset = self.m_tHitboxOffset[1][self.m_selectedHitbox]
		offsetOutline = self.m_tHitboxOffset[2][self.m_selectedHitbox]
		vertCount = self.m_vertCount
		vertCountOutline = self.m_vertCountOutline
	end
	if util.is_valid(self.m_bufHitboxVerts) == true then
		self.m_shader:Draw(
			drawCmd,
			ent,
			self.m_bufHitboxVerts,
			self.m_bufHitboxBoneIndices,
			cam:GetProjectionMatrix() * cam:GetViewMatrix(),
			vertCountOutline,
			offsetOutline
		)
	end
	if util.is_valid(self.m_bufFlatVerts) == true then
		self.m_shaderFlat:Draw(
			drawCmd,
			ent,
			self.m_bufFlatVerts,
			self.m_bufFlatBoneIndices,
			cam:GetProjectionMatrix() * cam:GetViewMatrix(),
			vertCount,
			offset
		)
	end
end
gui.register("WIModelEditorHitboxes", gui.WIModelEditorHitboxes)
