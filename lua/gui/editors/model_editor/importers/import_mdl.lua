local r = "Feature currently disabled" -- engine.load_library("wv_mde")
if r ~= true then
	console.print("WARNING: An error occured trying to load the 'wv_mde' module: ", r)
	return
end

local fImport = function(pEditor, mdl, mdlName, fOpen, importType, tFiles)
	local fNames = {}
	local p = mdlName:find("%.") -- Might have ".dx80.vtx" extension or similar
	if p ~= nil then
		mdlName = mdlName:sub(1, p - 1)
	end

	local vtxPriorityOrder = {
		["sw.vtx"] = 1,
		["xbox.vtx"] = 2,
		["dx80.vtx"] = 3,
		["dx90.vtx"] = 4,
	}
	local prevVtxIdx = -1
	local tRemove = {}
	for _, f in ipairs(tFiles) do
		local ext = file.get_file_extension(f)
		local fName = f
		local p = fName:find("%.")
		if p ~= nil then
			fName = fName:sub(1, p - 1)
		end
		if fName == mdlName then
			if ext ~= nil then
				if ext == "ani" then
					fNames["ani"] = f
				elseif ext == "mdl" then
					fNames["mdl"] = f
				elseif ext == "phy" then
					fNames["phy"] = f
				elseif ext == "vvd" then
					fNames["vvd"] = f
				elseif ext == "vtx" then
					local p = f:find("%.")
					local vtxExt = f:sub(p + 1, -1)
					local vtxExtIdx = vtxPriorityOrder[vtxExt] or 0
					if vtxExtIdx >= prevVtxIdx then
						prevVtxIdx = vtxExtIdx
						fNames["vtx"] = f
					end
				end
			end
			table.insert(tRemove, f)
		end
	end
	for _, f in ipairs(tRemove) do
		for i, fOther in ipairs(tFiles) do
			if fOther == f then
				table.remove(tFiles, i) -- Remove all files from the import list
				break
			end
		end
	end
	if fNames["mdl"] == nil then
		return false
	end
	local files = {}
	for ext, fName in pairs(fNames) do
		files[ext] = game.open_dropped_file(fName, true)
	end
	if files["mdl"] == nil then
		return false
	end
	return mde.load_mdl(mdlName, files, mdl, (importType == gui.WIModelEditor.IMPORT_TYPE_PHYSICS) and true or false)
end

for _, ext in ipairs({ "ani", "vtx", "mdl", "phy", "vvd" }) do
	gui.WIModelEditor.register_importer(
		ext,
		bit.bor(
			gui.WIModelEditor.IMPORT_TYPE_MESH,
			gui.WIModelEditor.IMPORT_TYPE_ANIMATION,
			gui.WIModelEditor.IMPORT_TYPE_PHYSICS
		),
		fImport
	)
end
