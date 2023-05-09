include("/class_objmesh.lua")
gui.WIModelViewer.register_importer(
	"obj",
	gui.WIModelViewer.IMPORT_TYPE_MESH,
	function(pEditor, mdl, mdlName, fOpen, importType, tFiles)
		local f = fOpen(false)
		if f == nil then
			return false
		end
		local objMdl = util.ObjMesh.Load(f)
		local objs = objMdl:GetObjects()
		local mesh = Model.Mesh.Create()
		for _, obj in ipairs(objs) do
			local verts, triangles = obj:CalculateUniqueVertices()

			local subMesh = Model.Mesh.Sub.create()
			for _, v in ipairs(verts) do
				subMesh:AddVertex(v)
			end
			for i = 1, #triangles, 3 do
				subMesh:AddTriangle(triangles[i] - 1, triangles[i + 1] - 1, triangles[i + 2] - 1)
			end
			subMesh:Optimize()
			subMesh:Update()

			mesh:AddSubMesh(subMesh)
		end
		mesh:Update()
		local group = mdl:GetMeshGroup(0)
		group:AddMesh(mesh)
		return true
	end
)
