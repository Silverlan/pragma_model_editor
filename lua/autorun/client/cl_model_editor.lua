--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

tool = tool or {}
tool.close_model_editor = function()
	if(tool.is_model_editor_open() == false) then return end
	tool.editor:Close()
	tool.editor = nil
end
tool.get_model_editor = function() return tool.editor end
tool.is_model_editor_open = function() return util.is_valid(tool.editor) end
tool.open_model_editor = function()
	include("/gui/editors/model_editor/wimodeleditor.lua")
	tool.close_model_editor()
	tool.editor = gui.create("WIModelEditor")
	tool.editor:SetAutoAlignToParent(true)
	-- tool.editor:SetZPos(1000)

	tool.editor:Open()
	return tool.editor
end

console.register_command("tool_model_editor",function(pl,...)
	local reload = false
	for cmd,args in pairs(console.parse_command_arguments({...})) do
		if(cmd == "reload") then reload = true end
	end

	if(tool.is_model_editor_open()) then
		if(reload) then
			local mdlEd = tool.get_model_editor()
			local mdlPath = mdlEd:GetModelName()
			mdlEd:Close()
			mdlEd = tool.open_model_editor()
			if(mdlPath ~= nil) then mdlEd:SetModel(mdlPath) end
			return
		end
		tool.close_model_editor()
		return
	end

	tool.open_model_editor()
end)
