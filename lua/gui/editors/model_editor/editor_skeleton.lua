include("/gui/pfm/treeview.lua")
include("/shaders/mde/mde_vertex_weights.lua")

util.register_class("gui.WIModelEditorSkeleton",gui.Base,gui.WIModelEditorPanel)

local MARGIN_OFFSET = 20

function gui.WIModelEditorSkeleton:__init()
	gui.Base.__init(self)
	gui.WIModelEditorPanel.__init(self)
end 
function gui.WIModelEditorSkeleton:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_shader = shader.get("mde_skeleton")
	self.m_shaderWeights = shader.get("mde_vertex_weights")

	local scrollContainer = gui.create("WIScrollContainer",self)
	scrollContainer:SetAutoAlignToParent(true)

	local pBones = gui.create("WIPFMTreeView",scrollContainer)
	pBones:SetX(MARGIN_OFFSET)
	-- pBones:SetScrollable(true)
	pBones:SetSelectable(gui.Table.SELECTABLE_MODE_SINGLE)
	pBones:SetAutoSelectChildren(false)
	self.m_pBones = pBones
end
local hullColor = Color.Magenta:Copy()
hullColor = hullColor:ToVector4()

local dsWeight = util.DataStream()
dsWeight:WriteVector4(hullColor)
dsWeight:WriteUInt32(0)

function gui.WIModelEditorSkeleton:PrepareRendering(pModelView)
	if(self:GetShowItems() == false) then return end
	pModelView:ScheduleEntityForRendering(self.m_shaderWeights,nil,function(ent,mdl,mesh,subMesh,mat)
		return true
	end)
end
function gui.WIModelEditorSkeleton:Render(drawCmd,cam,pModelView)
	local ent = self:GetEntity()
	if(self:GetShowItems() == false or util.is_valid(self.m_bufVerts) == false or util.is_valid(self.m_bufBoneIndices) == false) then return end
	self.m_shader:Draw(drawCmd,ent,self.m_bufVerts,self.m_bufBoneIndices,cam:GetProjectionMatrix() *cam:GetViewMatrix())

	--[[local pEditor = self:GetEditor()
	local ent = self:GetEntity()
	if(self:GetShowItems() == false or util.is_valid(self.m_bufVerts) == false or util.is_valid(self.m_bufBoneIndices) == false or util.is_valid(pEditor) == false) then return end
	self.m_shader:Draw(drawCmd,ent,self.m_bufVerts,self.m_bufBoneIndices,cam:GetProjectionMatrix() *cam:GetViewMatrix())

	for boneId,b in pairs(self.m_selectedBones) do
		local pModelView = pEditor:GetModelView()
		local shaderWeights = self.m_shaderWeights
		pModelView:RenderEntity(shaderWeights,function(ent,mdl,meshGroupId,meshGroup,mesh,subMesh,mat)
				return true
			end,drawCmd,function(shaderWeights,drawCmd)
				dsWeight:Seek(util.SIZEOF_VECTOR4)
				dsWeight:WriteUInt32(boneId)
				return shaderWeights:RecordPushConstants(dsWeight,shader.TexturedLit3D.PUSH_CONSTANTS_USER_DATA_OFFSET)
			end
		)
	end]]
end
local function add_bones(self,pList,bone)
	local ent = self:GetEntity()
	local pEl = pList:AddItem(bone:GetName())
	local function apply_bone_color(bone,color)
		for boneId,boneChild in pairs(bone:GetChildren()) do
			apply_bone_color(boneChild,color)

			local offset = self.m_bufBoneOffsets[boneId]
      if(self.m_bufVerts:MapMemory(0,util.SIZEOF_VECTOR3 *4) == true) then
        local ds = util.DataStream()
        ds:WriteVector4(color)
        self.m_bufVerts:WriteMemory(util.SIZEOF_VECTOR3,ds)
        self.m_bufVerts:WriteMemory(util.SIZEOF_VECTOR3 *2 +util.SIZEOF_VECTOR4,ds)
        self.m_bufVerts:UnmapMemory()
      end
		end
	end
	local function get_bone_id(pEl)
		if(util.is_valid(ent) == false) then return -1 end
		local mdlComponent = ent:GetComponent(ents.COMPONENT_MODEL)
		if(mdlComponent == nil) then return -1 end
		local name = pEl:GetText()
		return mdlComponent:LookupBone(name)
	end
	local function set_bone_color(boneId,color)
		if(self:IsValid() == false or util.is_valid(ent) == false or util.is_valid(self.m_bufVerts) == false) then return end
		local mdlComponent = ent:GetComponent(ents.COMPONENT_MODEL)
		local mdl = (mdlComponent ~= nil) and mdlComponent:GetModel() or nil
		if(self.m_bufBoneOffsets[boneId] == nil or util.is_valid(mdl) == false) then return end
		local skeleton = mdl:GetSkeleton()
		local bone = skeleton:GetBone(boneId)
		if(bone == nil) then return end
		local vColor = color:ToVector4()
		apply_bone_color(bone,vColor)
		for boneId,boneChild in pairs(bone:GetChildren()) do
			apply_bone_color(boneChild,vColor)
		end
	end
	pEl:AddCallback("OnSelected",function(pEl)
		local boneId = get_bone_id(pEl)
		self:GetEntity():GetComponent(ents.COMPONENT_MDE_MODEL_PREVIEW):SetBoneSelected(boneId,true)
		self:GetEditor():ScheduleEntityForRendering()
		if(boneId == -1) then return end
		set_bone_color(boneId,Color.Aqua)
	end)
	pEl:AddCallback("OnDeselected",function(pEl)
		local boneId = get_bone_id(pEl)
		self:GetEntity():GetComponent(ents.COMPONENT_MDE_MODEL_PREVIEW):SetBoneSelected(boneId,false)
		self:GetEditor():ScheduleEntityForRendering()
		set_bone_color(boneId,Color.OrangeRed)
	end)
	local children = bone:GetChildren()
	for boneId,bone in pairs(children) do
		add_bones(self,pEl,bone)
	end
end
function gui.WIModelEditorSkeleton:UpdateSkeleton()
	local ent = self:GetEntity()
	if(util.is_valid(ent) == false or self.m_shader == nil) then return end
	local bufVerts,bufBoneIndices,offsets = self.m_shader:CreateBuffers(ent)
	if(bufVerts == nil) then return end
	self.m_bufVerts = bufVerts
	self.m_bufBoneIndices = bufBoneIndices
	self.m_bufBoneOffsets = offsets
end
function gui.WIModelEditorSkeleton:SetModel(mdl)
	local pSkeleton = self.m_pBones
	if(util.is_valid(pSkeleton) == false) then return end
	pSkeleton:Clear()

	if(util.is_valid(mdl) == false) then return end
	local skeleton = mdl:GetSkeleton()
	local bones = skeleton:GetRootBones()
	for boneId,bone in pairs(bones) do add_bones(self,pSkeleton,bone) end

	self:UpdateSkeleton()
	pSkeleton:ExpandAll()
end
function gui.WIModelEditorSkeleton:OnSizeChanged(w,h)
	gui.Base.OnSizeChanged(self,w,h)
	if(util.is_valid(self.m_pBones)) then self.m_pBones:SetWidth(w -20) end
end
gui.register("WIModelEditorSkeleton",gui.WIModelEditorSkeleton)
