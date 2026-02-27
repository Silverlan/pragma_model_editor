-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("gui.WIModelEditorAttachments", gui.Base, gui.WIModelEditorPanel)
local MARGIN_OFFSET = 20

function gui.WIModelEditorAttachments:__init()
	gui.Base.__init(self)
	gui.WIModelEditorPanel.__init(self)
end
function gui.WIModelEditorAttachments:OnInitialize()
	gui.Base.OnInitialize(self)

	local pAttachments = gui.create("WITable", self)
	pAttachments:SetHeight(186)
	pAttachments:SetAutoAlignToParent(true, false)
	pAttachments:SetScrollable(true)
	pAttachments:SetSelectableMode(gui.Table.SELECTABLE_MODE_SINGLE)
	pAttachments:SetRowHeight(20)
	local pHeader = pAttachments:AddHeaderRow()
	pHeader:SetValue(0, locale.get_text("id"))
	pHeader:SetValue(1, locale.get_text("name"))
	pHeader:SetValue(2, locale.get_text("bone"))
	pHeader:SetValue(3, locale.get_text("angles"))
	pHeader:SetValue(4, locale.get_text("offset"))
	self.m_pAttachments = pAttachments

	local lbName = gui.create("WIText", self)
	lbName:SetText(locale.get_text("name") .. ":")
	lbName:SizeToContents()
	self.m_lbName = lbName

	local teName = gui.create("WITextEntry", self)
	teName:SetSize(140, 20)
	self.m_teName = teName

	local lbBone = gui.create("WIText", self)
	lbBone:SetText(locale.get_text("bone") .. ":")
	lbBone:SizeToContents()
	self.m_lbBone = lbBone

	local teBone = gui.create("WITextEntry", self)
	teBone:SetSize(140, 20)
	self.m_teBone = teBone

	local lbOffset = gui.create("WIText", self)
	lbOffset:SetText(locale.get_text("offset") .. ":")
	lbOffset:SizeToContents()
	self.m_lbOffset = lbOffset

	local teOffset = gui.create("WITextEntry", self)
	teOffset:SetSize(240, 20)
	self.m_teOffset = teOffset

	local lbAngles = gui.create("WIText", self)
	lbAngles:SetText(locale.get_text("angles") .. ":")
	lbAngles:SizeToContents()
	self.m_lbAngles = lbAngles

	local teAngles = gui.create("WITextEntry", self)
	teAngles:SetSize(240, 20)
	self.m_teAngles = teAngles

	local pButtonAdd = gui.create("WIButton", self)
	pButtonAdd:SetText(locale.get_text("mde_add_attachment"))
	pButtonAdd:SizeToContents()
	pButtonAdd:AddCallback("OnPressed", function(pButtonAdd)
		if self:IsValid() == false then
			return
		end
		local pEditor = self:GetEditor()
		if util.is_valid(pEditor) == false then
			return
		end
		local mdl = pEditor:GetModel()
		if util.is_valid(mdl) == false then
			return
		end
		mdl:AddAttachment(
			teName:GetText(),
			teBone:GetText(),
			vector.create_from_string(teOffset:GetText()),
			angle.create_from_string(teAngles:GetText())
		)
		self:SetModel(mdl)
	end)
	self.m_pButtonAdd = pButtonAdd

	local pRemove = gui.create("WIButton", self)
	pRemove:SetText(locale.get_text("mde_remove_attachment"))
	pRemove:SizeToContents()
	pRemove:AddCallback("OnPressed", function(pRemove)
		if self:IsValid() == false then
			return
		end
		local pEditor = self:GetEditor()
		if util.is_valid(pEditor) == false then
			return
		end
		local mdl = pEditor:GetModel()
		if util.is_valid(mdl) == false then
			return
		end
		local pRow = self.m_pAttachments:GetFirstSelectedRow()
		if pRow == nil then
			return
		end
		local attId = pRow:GetValue(0)
		mdl:RemoveAttachment(tonumber(attId))
		self:SetModel(mdl)
	end)
	self.m_pRemove = pRemove

	local pEdit = gui.create("WIButton", self)
	pEdit:SetText(locale.get_text("mde_edit_attachment"))
	pEdit:SizeToContents()
	pEdit:AddCallback("OnPressed", function(pEdit)
		if self:IsValid() == false then
			return
		end
		local pEditor = self:GetEditor()
		if util.is_valid(pEditor) == false then
			return
		end
		local mdl = pEditor:GetModel()
		if util.is_valid(mdl) == false then
			return
		end
		local pRow = self.m_pAttachments:GetFirstSelectedRow()
		if pRow == nil then
			return
		end
		local attId = pRow:GetValue(0)
		mdl:SetAttachmentData(tonumber(attId), {
			angles = angle.create_from_string(teAngles:GetText()),
			offset = vector.create_from_string(teOffset:GetText()),
			name = teName:GetText(),
			bone = teBone:GetText(),
		})
		self:SetModel(mdl)
		local pRow = self.m_pAttachments:GetRow(tonumber(attId))
		if pRow ~= nil then
			pRow:Select()
		end
	end)
	self.m_pEdit = pEdit
end
function gui.WIModelEditorAttachments:Render(drawCmd, cam)
	local pEditor = self:GetEditor()
	if self.m_attachment == nil or util.is_valid(pEditor) == false then
		return
	end
	local ent = pEditor:GetEntity()
	local mdlC = util.is_valid(ent) and ent:GetComponent(ents.COMPONENT_MODEL) or nil
	if mdlC == nil then
		return
	end
	local pos, rot = mdlC:GetAttachmentTransform(self.m_attachment)
	local m = Mat4(1.0)
	m:Translate(pos)
	m = m * rot:ToMatrix()
	m:Scale(Vector(10.0, 10.0, 10.0))
	pEditor:DrawAxis(m)
end
function gui.WIModelEditorAttachments:SetModel(mdl)
	self.m_attachment = nil
	local pAttachments = self.m_pAttachments
	if util.is_valid(pAttachments) == false then
		return
	end
	pAttachments:Clear()

	if util.is_valid(mdl) == false then
		return
	end
	local attachments = mdl:GetAttachments()
	local skeleton = mdl:GetSkeleton()
	for attId, att in ipairs(attachments) do
		local pRow = pAttachments:AddRow()
		local bone = skeleton:GetBone(att.bone)
		local boneName = (bone ~= nil) and bone:GetName() or tostring(att.bone)
		pRow:SetValue(0, tostring(attId - 1))
		pRow:SetValue(1, att.name)
		pRow:SetValue(2, boneName)
		pRow:SetValue(3, tostring(att.angles))
		pRow:SetValue(4, tostring(att.offset))
		pRow:AddCallback("OnSelected", function(pRow)
			if self:IsValid() == false then
				return
			end
			self:GetEditor():ScheduleEntityForRendering()
			self.m_attachment = attId - 1
			self.m_teName:SetText(att.name)
			self.m_teBone:SetText(boneName)
			self.m_teOffset:SetText(tostring(att.offset))
			self.m_teAngles:SetText(tostring(att.angles))
		end)
	end
end
function gui.WIModelEditorAttachments:OnSizeChanged(w, h)
	gui.Base.OnSizeChanged(self, w, h)

	if util.is_valid(self.m_pAttachments) == false then
		return
	end
	local yOffset = self.m_pAttachments:GetY() + self.m_pAttachments:GetHeight()
	local x = MARGIN_OFFSET
	local y = yOffset + MARGIN_OFFSET

	self.m_lbName:SetPos(x, y)
	x = x + self.m_lbName:GetWidth() + 2
	self.m_teName:SetPos(x, y)
	x = x + self.m_teName:GetWidth() + MARGIN_OFFSET

	self.m_lbBone:SetPos(x, y)
	x = x + self.m_lbBone:GetWidth() + 2
	self.m_teBone:SetPos(x, y)
	x = x + self.m_teBone:GetWidth() + MARGIN_OFFSET

	self.m_lbOffset:SetPos(x, y)
	x = x + self.m_lbOffset:GetWidth() + 2
	self.m_teOffset:SetPos(x, y)
	x = x + self.m_teOffset:GetWidth() + MARGIN_OFFSET

	self.m_lbAngles:SetPos(x, y)
	x = x + self.m_lbAngles:GetWidth() + 2
	self.m_teAngles:SetPos(x, y)
	x = x + self.m_teAngles:GetWidth() + MARGIN_OFFSET

	y = y + self.m_lbName:GetHeight() + MARGIN_OFFSET
	x = MARGIN_OFFSET
	self.m_pButtonAdd:SetPos(x, y)
	x = x + self.m_pButtonAdd:GetWidth() + 4

	self.m_pRemove:SetPos(x, y)
	x = x + self.m_pRemove:GetWidth() + 4

	self.m_pEdit:SetPos(x, y)
	x = x + self.m_pEdit:GetWidth() + 4
end
gui.register("model_editor_attachments", gui.WIModelEditorAttachments)
