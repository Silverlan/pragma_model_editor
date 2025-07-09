-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local r = "Feature currently disabled" -- engine.load_library("wv_mde")
if r ~= true then
	console.print("WARNING: An error occured trying to load the 'wv_mde' module: ", r)
	return
end
gui.WIModelEditor.register_importer(
	"fbx",
	gui.WIModelEditor.IMPORT_TYPE_MESH,
	function(pEditor, mdl, mdlName, fOpen, importType, tFiles)
		local f = fOpen(true)
		if f == nil then
			return false
		end
		return mde.load_fbx(mdlName, f, mdl)
	end
)
