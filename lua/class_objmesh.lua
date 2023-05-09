local VERTEX_EPSILON = 0.001

util.register_class("util.ObjMeshObject")
function util.ObjMeshObject:__init(name)
	self.m_name = name
	self.m_verts = {}
	self.m_uvs = {}
	self.m_normals = {}
	self.m_faces = {}
end

function util.ObjMeshObject:GetVertices()
	return self.m_verts
end
function util.ObjMeshObject:GetUVCoordinates()
	return self.m_uvs
end
function util.ObjMeshObject:GetNormals()
	return self.m_normals
end
function util.ObjMeshObject:GetName()
	return self.m_name
end
function util.ObjMeshObject:AddVertex(v)
	table.insert(self.m_verts, v)
end
function util.ObjMeshObject:AddUVCoordinates(uv)
	table.insert(self.m_uvs, uv)
end
function util.ObjMeshObject:AddNormal(n)
	table.insert(self.m_normals, n)
end
function util.ObjMeshObject:AddFace(face)
	table.insert(self.m_faces, face)
end
function util.ObjMeshObject:GetFaces()
	return self.m_faces
end
function util.ObjMeshObject:CalculateUniqueVertices()
	local verts = {}
	local function add_unique_vertex(pos, uv, n)
		--[[for i,v in ipairs(verts) do
			if(
				(math.abs(pos.x -v.position.x) <= VERTEX_EPSILON and math.abs(pos.y -v.position.y) <= VERTEX_EPSILON and math.abs(pos.z -v.position.z) <= VERTEX_EPSILON) and
				(uv == nil or (math.abs(uv.x -v.uv.x) <= VERTEX_EPSILON and math.abs(uv.y -v.uv.y) <= VERTEX_EPSILON)) and
				(n == nil or (math.abs(n.x -v.normal.x) <= VERTEX_EPSILON and math.abs(n.y -v.normal.y) <= VERTEX_EPSILON and math.abs(n.z -v.normal.z) <= VERTEX_EPSILON))
			) then
				return i
			end
		end]]
		-- Too expensive for large meshes; Optimization will have to be done by caller!
		table.insert(verts, Vertex(pos, uv or Vector2(), n or Vector()))
		return #verts
	end
	local triangles = {}
	for _, f in ipairs(self.m_faces) do
		for i = 1, 3 do
			local v = f[i]
			local pos = self.m_verts[v.vertexid]
			local uv = self.m_uvs[v.uvid]
			local n = self.m_normals[v.normalid]
			table.insert(triangles, add_unique_vertex(pos, uv, n))
		end
	end
	return verts, triangles
end

class("ObjMesh")
function ObjMesh:__init(objects)
	self.m_objects = objects
end

function ObjMesh:GetObjects()
	return self.m_objects
end

local function to_triangles(vertices, triangles)
	local pivot = 0
	local va = vertices[pivot + 1]
	local numVerts = #vertices
	local numVals = (numVerts - 2) * 3
	local idx = 0
	for i = (pivot + 2), (numVerts - 1) do
		triangles[idx + 1] = vertices[pivot + 1]
		triangles[idx + 2] = vertices[i]
		triangles[idx + 3] = vertices[i + 1]
		idx = idx + 3
	end
end

local function trim(s)
	-- from PiL2 20.4
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end
ObjMesh.Load = function(fName)
	local f
	if type(fName) == "string" then
		f = file.open(fName, "rb")
	else
		f = fName
	end
	if f == nil then
		return
	end
	local objects = {}
	local function get_object()
		local numObjs = #objects
		if numObjs == 0 then
			table.insert(objects, util.ObjMeshObject("generic"))
		end
		return objects[#objects]
	end
	while not f:Eof() do
		local l = f:ReadLine()
		if l[0] ~= "#" then
			local sp = l:find("%s")
			if sp ~= nil then
				local v = l:sub(0, sp - 1)
				local val = trim(l:sub(sp + 1))
				if v == "o" then
					if val:sub(-4) == ".obj" then
						val = val:sub(0, -5)
					end
					table.insert(objects, util.ObjMeshObject(val))
				elseif v == "v" then -- Vertices
					local obj = get_object()
					local exp = val:split(" ")
					obj:AddVertex(Vector(tonumber(exp[1] or 0), tonumber(exp[2] or 0), tonumber(exp[3] or 0)))
				elseif v == "vt" then -- UV coordinates
					local obj = get_object()
					local exp = val:split(" ")
					obj:AddUVCoordinates(Vector2(tonumber(exp[1] or 0), tonumber(exp[2] or 0)))
				elseif v == "vn" then -- Normals
					local obj = get_object()
					local exp = val:split(" ")
					obj:AddNormal(Vector(tonumber(exp[1] or 0), tonumber(exp[2] or 0), tonumber(exp[3] or 0)))
				elseif v == "f" then -- Faces
					local obj = get_object()
					local exp = val:split(" ")
					local verts = {}
					for i, v in ipairs(exp) do
						exp[i] = v:split("/")
						table.insert(verts, {
							vertexid = tonumber(exp[i][1]),
							uvid = tonumber(exp[i][2]),
							normalid = tonumber(exp[i][3]),
						})
					end
					local triangles = {}
					to_triangles(verts, triangles)
					obj:AddFace(triangles)
				end
			end
		end
	end
	f:Close()
	return ObjMesh(objects)
end
