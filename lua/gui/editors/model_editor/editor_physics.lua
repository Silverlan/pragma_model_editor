local bPclSuccess = engine.load_library("pcl/pr_pcl")
if(bPclSuccess ~= true) then
  console.print("WARNING: An error occured trying to load the 'pr_pcl' module: ",bPclSuccess)
end

util.register_class("gui.WIModelEditorPhysics",gui.Base,gui.WIModelEditorPanel)
function gui.WIModelEditorPhysics:__init()
	gui.Base.__init(self)
	gui.WIModelEditorPanel.__init(self)
end
function gui.WIModelEditorPhysics:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_selected = nil
	self.m_tPhysBuffers = {}
	local pPhysics = gui.create("WITable",self)
	pPhysics:SetHeight(186)
	pPhysics:SetAutoAlignToParent(true,false)
	pPhysics:SetScrollable(true)
	pPhysics:SetSelectableMode(gui.Table.SELECTABLE_MODE_SINGLE)
	pPhysics:SetRowHeight(20)
	local pHeader = pPhysics:AddHeaderRow()
	pHeader:SetValue(0,locale.get_text("id"))
	pHeader:SetValue(1,locale.get_text("bone"))
	pHeader:SetValue(2,locale.get_text("convex"))
	pHeader:SetValue(3,locale.get_text("origin"))
	pHeader:SetValue(4,locale.get_text("surface_material"))
	pHeader:SetValue(5,locale.get_text("vertex_count"))
	self.m_pPhysics = pPhysics

	self.m_shaderFlat = shader.get("mde_flat")
	self.m_shaderFlatWireframe = shader.get("mde_flat_wireframe")
end
function gui.WIModelEditorPhysics:Render(drawCmd,cam)
	local ent = self:GetEntity()
	local function draw(o)
		if(util.is_valid(o[1]) == true) then
			self.m_shaderFlat:Draw(drawCmd,ent,o[1],o[3],cam:GetProjectionMatrix() *cam:GetViewMatrix())
			self.m_shaderFlatWireframe:Draw(drawCmd,ent,o[2],o[3],cam:GetProjectionMatrix() *cam:GetViewMatrix())
		end
	end
	if(self:IsSelected() and self.m_selected ~= nil) then
		if(self.m_tPhysBuffers[self.m_selected] ~= nil) then -- Can be nil if pcl library couldn't be loaded
			draw(self.m_tPhysBuffers[self.m_selected])
		end
		return
	end
	if(self:GetShowItems() == false) then return end
	for _,o in ipairs(self.m_tPhysBuffers) do
		draw(o)
	end
end
function gui.WIModelEditorPhysics:SetModel(mdl)
	self.m_selected = nil
	self.m_tPhysBuffers = {}
	local pPhysics = self.m_pPhysics
	if(util.is_valid(pPhysics) == false) then return end
	pPhysics:Clear()

	if(util.is_valid(mdl) == false) then return end
	local skeleton = mdl:GetSkeleton()
	local meshes = mdl:GetCollisionMeshes()
	for i,mesh in ipairs(meshes) do
		local pRow = pPhysics:AddRow()
		pRow:AddCallback("OnSelected",function(pRow)
			if(self:IsValid() == false) then return end
			local id = tonumber(pRow:GetValue(0))
			self.m_selected = i
			self:GetEditor():ScheduleEntityForRendering()
		end)
		local boneId = mesh:GetBoneParentId()
		local bone = skeleton:GetBone(boneId)
		local surfaceMaterial = phys.get_surface_material(mesh:GetSurfaceMaterialId())
		pRow:SetValue(0,tostring(i -1))
		pRow:SetValue(1,(bone ~= nil) and bone:GetName() or locale.get_text("none"))
		pRow:SetValue(2,(mesh:IsConvex() == true) and locale.get_text("yes") or locale.get_text("no"))
		pRow:SetValue(3,tostring(mesh:GetOrigin()))
		pRow:SetValue(4,(surfaceMaterial ~= nil) and surfaceMaterial:GetName() or locale.get_text("none"))
		pRow:SetValue(5,tostring(mesh:GetVertexCount()))
		if(bPclSuccess == true) then
			local dsFlatVerts = util.DataStream()
			local dsWireframeVerts = util.DataStream()
			local dsFlatIndices = util.DataStream()
			local col = Color.Chocolate
			col = col:ToVector4()
			col.w = 0.5

			local colWireframe = Color.Red
			colWireframe = colWireframe:ToVector4()

			local pointCloud = mesh:GetVertices()
			local verts,triangles = pcl.generate_poly_mesh(pointCloud)
			local origin = mesh:GetOrigin()
			for i=1,#triangles,3 do
				local idx0 = triangles[i]
				local idx1 = triangles[i +1]
				local idx2 = triangles[i +2]
				for _,idx in ipairs({idx0,idx1,idx2}) do
					local v = -origin +verts[idx +1]
					dsFlatVerts:WriteVector(v)
					dsFlatVerts:WriteVector4(col)

					dsWireframeVerts:WriteVector(v)
					dsWireframeVerts:WriteVector4(colWireframe)

					dsFlatIndices:WriteUInt32(boneId)
				end
			end
      local bufCreateInfo = prosper.BufferCreateInfo()
      bufCreateInfo.size = dsFlatVerts:GetSize()
      bufCreateInfo.usageFlags = prosper.BUFFER_USAGE_VERTEX_BUFFER_BIT
      bufCreateInfo.memoryFeatures = prosper.MEMORY_FEATURE_GPU_BULK_BIT
      
			local bufFlatVerts = prosper.create_buffer(bufCreateInfo,dsFlatVerts)
			if(bufFlatVerts == nil) then return end
      bufFlatVerts:SetDebugName("mdlviewer_physics_flat_verts")
      bufCreateInfo.size = dsWireframeVerts:GetSize()
			local bufWireframeVerts = prosper.create_buffer(bufCreateInfo,dsWireframeVerts)
			if(bufWireframeVerts == nil) then return end
      bufWireframeVerts:SetDebugName("mdlviewer_physics_wireframe_verts")
      bufCreateInfo.size = dsFlatIndices:GetSize()
			local bufFlatBoneIndices = prosper.create_buffer(bufCreateInfo,dsFlatIndices)
			if(bufFlatBoneIndices == nil) then return end
      bufFlatBoneIndices:SetDebugName("mdlviewer_physics_bone_indices")

			table.insert(self.m_tPhysBuffers,{bufFlatVerts,bufWireframeVerts,bufFlatBoneIndices})
		end
	end
end
function gui.WIModelEditorPhysics:OnSizeChanged(w,h)
	gui.Base.OnSizeChanged(self,w,h)
end
gui.register("WIModelEditorPhysics",gui.WIModelEditorPhysics)
