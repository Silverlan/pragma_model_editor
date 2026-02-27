-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local c = util.register_class("gui.WIModelEditorAnimations", gui.Base, gui.WIModelEditorPanel)
local MARGIN_OFFSET = 20

function gui.WIModelEditorAnimations:__init()
	gui.Base.__init(self)
	gui.WIModelEditorPanel.__init(self)
end
function gui.WIModelEditorAnimations:InitializeEvents(pTabEvents)
	local pEvents = gui.create("WITable", pTabEvents)
	pEvents:SetHeight(186)
	pEvents:SetAutoAlignToParent(true, false)
	pEvents:SetScrollable(true)
	pEvents:SetSelectableMode(gui.Table.SELECTABLE_MODE_SINGLE)
	pEvents:SetRowHeight(20)
	self.m_pEvents = pEvents

	local pContainer = gui.create("WIGridPanel", pTabEvents)
	self.m_pEventContainer = pContainer

	local pHeader = pEvents:AddHeaderRow()
	pHeader:SetValue(0, locale.get_text("frame"))
	pHeader:SetValue(1, locale.get_text("type"))
	pHeader:SetValue(2, locale.get_text("arguments"))

	local pGridPanel = gui.create("WIGridPanel")
	pGridPanel:SetSize(600, 65)
	pContainer:AddItem(pGridPanel, 0, 0)

	pGridPanel:AddItem(gui.create_label("Frame"), 0, 0) -- TODO: Localization
	local pFrameSlider = gui.create("WISlider")
	pFrameSlider:SetSize(140, 16)
	pFrameSlider:SetRange(0, 100)
	pFrameSlider:AddCallback("OnChange", function(pSlider, progress, value)
		if self:IsValid() == false or self.m_pFrameSlider:IsValid() == false then
			return
		end
		self.m_pFrameSlider:SetValue(value)
	end)
	self.m_pEventFrameSlider = pFrameSlider
	pGridPanel:AddItem(pFrameSlider, 0, 1)

	pGridPanel:AddItem(gui.create_label("Type"), 1, 0) -- TODO: Localization
	local pTypes = gui.create("WIDropDownMenu", self)
	self.m_pType = pTypes
	pTypes:SetEditable(true)
	pTypes:AddOption(locale.get_text("mde_ae_emit_sound"))
	pTypes:AddOption(locale.get_text("mde_ae_left_footstep"))
	pTypes:AddOption(locale.get_text("mde_ae_right_footstep"))
	pTypes:SetOptionValue(0, tostring(Animation.EVENT_EMITSOUND))
	pTypes:SetOptionValue(1, tostring(Animation.EVENT_FOOTSTEP_LEFT))
	pTypes:SetOptionValue(2, tostring(Animation.EVENT_FOOTSTEP_RIGHT))
	pTypes:SetSize(140, 20)
	pGridPanel:AddItem(pTypes, 1, 1)

	pGridPanel:AddItem(gui.create_label("Arguments"), 2, 0) -- TODO: Localization
	local pArguments = gui.create("WITextEntry", self)
	pArguments:SetSize(440, 20)
	self.m_pArguments = pArguments
	pGridPanel:AddItem(pArguments, 2, 1)

	local pButtonApplyChanges = gui.create("WIButton")
	pButtonApplyChanges:SetText(locale.get_text("apply_changes"))
	pButtonApplyChanges:SizeToContents()
	pButtonApplyChanges:AddCallback("OnPressed", function(pButton)
		if self:IsValid() == false then
			return
		end
		local anim = self:GetSelectedAnimation()
		if anim == nil then
			return
		end
		local pRow = self.m_pEvents:GetFirstSelectedRow()
		if pRow == nil then
			return
		end
		if util.is_valid({ self.m_pType, self.m_pArguments, anim }) == false or self.m_selectedEventIdx == nil then
			return
		end
		local evType = tonumber(self.m_pType:GetText()) or tonumber(self.m_pType:GetValue())
		if evType == nil then
			return
		end
		anim:RemoveEvent(tonumber(pRow:GetValue(0)), self.m_selectedEventIdx)
		anim:AddEvent(pFrameSlider:GetValue(), evType, string.split(self.m_pArguments:GetText(), ","))
		self:ReloadEvents()
	end)
	pContainer:AddItem(pButtonApplyChanges, 1, 0)

	local pButtonAddEvent = gui.create("WIButton")
	pButtonAddEvent:SetText(locale.get_text("mde_add_event"))
	pButtonAddEvent:SizeToContents()
	pButtonAddEvent:AddCallback("OnPressed", function(pButton)
		if self:IsValid() == false or pFrameSlider:IsValid() == false or pTypes:IsValid() == false then
			return
		end
		local anim = self:GetSelectedAnimation()
		if anim == nil then
			return
		end
		local evType = tonumber(pTypes:GetValue()) or tonumber(pTypes:GetText())
		if evType == nil then
			return
		end
		local args = {}
		if util.is_valid(self.m_pArguments) == true then
			args = string.split(self.m_pArguments:GetText(), ",")
		end
		anim:AddEvent(pFrameSlider:GetValue(), evType, args)
		self:ReloadEvents()
	end)
	pContainer:AddItem(pButtonAddEvent, 1, 1)

	local pButtonAddEvent = gui.create("WIButton")
	pButtonAddEvent:SetText(locale.get_text("mde_remove_event"))
	pButtonAddEvent:SizeToContents()
	pButtonAddEvent:AddCallback("OnPressed", function(pButton)
		if self:IsValid() == false or self.m_selectedEventIdx == nil then
			return
		end
		local anim = self:GetSelectedAnimation()
		if anim == nil then
			return
		end
		local pRow = self.m_pEvents:GetFirstSelectedRow()
		if pRow == nil then
			return
		end
		anim:RemoveEvent(tonumber(pRow:GetValue(0)), self.m_selectedEventIdx)
		self:ReloadEvents()
	end)
	pContainer:AddItem(pButtonAddEvent, 1, 2)
end
function gui.WIModelEditorAnimations:InitializeBlendControllers(pTabBlendControllers)
	local pBlendControllers = gui.create("WITable", pTabBlendControllers)
	pBlendControllers:SetHeight(186)
	pBlendControllers:SetAutoAlignToParent(true, false)
	pBlendControllers:SetScrollable(true)
	pBlendControllers:SetSelectableMode(gui.Table.SELECTABLE_MODE_SINGLE)
	pBlendControllers:SetRowHeight(20)
	self.m_pBlendControllers = pBlendControllers

	local pHeader = pBlendControllers:AddHeaderRow()
	pHeader:SetValue(0, locale.get_text("animation"))
	pHeader:SetValue(1, locale.get_text("mde_transition"))

	local pContainer = gui.create("WIGridPanel", pTabBlendControllers)
	self.m_pBlendControllerContainer = pContainer

	local pGridPanel = gui.create("WIGridPanel")
	pGridPanel:SetSize(600, 65)
	pContainer:AddItem(pGridPanel, 0, 0)

	pGridPanel:AddItem(gui.create_label("blend_controller"), 0, 0)
	local pBlendController = gui.create("WITextEntry")
	pBlendController:SetSize(440, 20)
	self.m_pBlendController = pBlendController
	pGridPanel:AddItem(pBlendController, 0, 1)
end
function gui.WIModelEditorAnimations:InitializeAnimation(pTabAnimation)
	local pGridPanel = gui.create("WIGridPanel", pTabAnimation)
	pGridPanel:SetRowHeight(20)
	self.m_pAnimGridPanel = pGridPanel

	local pAnimations = gui.create("WITable", pTabAnimation)
	pAnimations:SetHeight(186)
	pAnimations:SetName("animations")
	pAnimations:SetAutoAlignToParent(true, false)
	pAnimations:SetScrollable(true)
	pAnimations:SetSelectableMode(gui.Table.SELECTABLE_MODE_SINGLE)
	pAnimations:SetRowHeight(20)
	self.m_pAnimations = pAnimations

	self.m_tFlags = {}
	local function set_anim_flag(flag, b)
		local anim = self:GetSelectedAnimation()
		if anim == nil then
			return
		end
		local flags = anim:GetFlags()
		if b == true then
			anim:AddFlags(flag)
		else
			anim:RemoveFlags(flag)
		end
	end
	self.m_pCbLoop = self:AddFlag(locale.get_text("mde_anim_flag_loop"), function(pCb, b)
		set_anim_flag(Animation.FLAG_LOOP, b)
	end, locale.get_text("mde_anim_flag_loop_desc"))
	self.m_pCbNoRepeat = self:AddFlag(locale.get_text("mde_anim_flag_no_repeat"), function(pCb, b)
		set_anim_flag(Animation.FLAG_NOREPEAT, b)
	end, locale.get_text("mde_anim_flag_no_repeat_desc"))
	self.m_pCbMoveX = self:AddFlag(locale.get_text("mde_anim_flag_move_x"), function(pCb, b)
		set_anim_flag(Animation.FLAG_MOVEX, b)
	end, locale.get_text("mde_anim_flag_move_x_desc"))
	self.m_pCbMoveY = self:AddFlag(locale.get_text("mde_anim_flag_move_z"), function(pCb, b)
		set_anim_flag(Animation.FLAG_MOVEZ, b)
	end, locale.get_text("mde_anim_flag_move_z_desc"))
	self.m_pCbAutoplay = self:AddFlag(locale.get_text("mde_anim_flag_autoplay"), function(pCb, b)
		set_anim_flag(Animation.FLAG_AUTOPLAY, b)
		if b == true and util.is_valid(self.m_pCbGesture) == true then
			self.m_pCbGesture:SetChecked(b)
		end
	end, locale.get_text("mde_anim_flag_autoplay_desc"))
	self.m_pCbGesture = self:AddFlag(locale.get_text("mde_anim_flag_gesture"), function(pCb, b)
		set_anim_flag(Animation.FLAG_GESTURE, b)
	end, locale.get_text("mde_anim_flag_gesture_desc"))

	local i = pGridPanel:GetRowCount()

	local pActivity = gui.create("WIDropDownMenu")
	pActivity:SetSize(240, 20)
	for id, name in pairs(Animation.GetActivityEnums()) do
		pActivity:AddOption(name)
		pActivity:SetOptionValue(pActivity:GetOptionCount() - 1, tostring(Animation[name]))
	end
	self.m_pActivity = pActivity
	pGridPanel:AddItem(pActivity, i, 1)

	pGridPanel:AddItem(gui.create_label(locale.get_text("mde_activity") .. ":"), i, 0)
	i = i + 1

	local pActivityWeight = gui.create("WINumericEntry")
	pActivityWeight:SetSize(140, 20)
	pActivityWeight:SetRange(-1, 50)
	pActivityWeight:SetMaxLength(2)
	pActivityWeight:AddCallback("OnTextEntered", function(pWeight)
		if self:IsValid() == false then
			return
		end
		local weight = tonumber(pWeight:GetText())
		local anim = self:GetSelectedAnimation()
		if anim == nil then
			return
		end
		anim:SetActivityWeight(weight)
	end)
	self.m_pActivityWeight = pActivityWeight
	pGridPanel:AddItem(pActivityWeight, i, 1)

	pGridPanel:AddItem(gui.create_label(locale.get_text("mde_activity_weight") .. ":"), i, 0)
	i = i + 1

	pGridPanel:AddItem(gui.create_label(locale.get_text("fps")), i, 0)
	local pFPS = gui.create("WINumericEntry")
	pFPS:SetSize(140, 20)
	pFPS:SetRange(0, 100)
	pFPS:SetMaxLength(3)
	pFPS:AddCallback("OnTextEntered", function(pFPS)
		if self:IsValid() == false then
			return
		end
		local fps = tonumber(pFPS:GetText())
		local anim = self:GetSelectedAnimation()
		if anim == nil then
			return
		end
		anim:SetFPS(fps)
	end)
	self.m_pFPS = pFPS
	pGridPanel:AddItem(pFPS, i, 1)

	i = i + 1
	pGridPanel:AddItem(gui.create_label(locale.get_text("mde_anim_fade_in_time")), i, 0)
	i = i + 1
	pGridPanel:AddItem(gui.create_label(locale.get_text("mde_anim_fade_out_time")), i, 0)
end
function gui.WIModelEditorAnimations:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(256, 512)
	local pTabPanel = gui.create("tabbed_panel", self, 0, 0, self:GetWidth(), self:GetHeight())
	local pTabAnimation = pTabPanel:AddTab(locale.get_text("animation"))
	local pTabEvents = pTabPanel:AddTab(locale.get_text("events"))
	local pTabBlendControllers = pTabPanel:AddTab(locale.get_text("mde_blend_controllers"))
	self:InitializeBlendControllers(pTabBlendControllers)
	self.m_pTabAnimations = pTabAnimation
	self:InitializeEvents(pTabEvents)
	self:InitializeAnimation(pTabAnimation)
	self.m_pTabPanel = pTabPanel

	local pLabelFrame = gui.create("WIText", self)
	pLabelFrame:SetText(locale.get_text("frame") .. ":")
	pLabelFrame:SizeToContents()
	self.m_pLabelFrame = pLabelFrame

	local pFrameSlider = gui.create("WISlider", self)
	pFrameSlider:SetSize(256, 16)
	pFrameSlider:AddCallback("OnChange", function(pSlider, progress, value)
		if self:IsValid() == false or self.m_bUpdateCycle == false then
			return
		end
		local ent = self:GetEntity()
		if util.is_valid(ent) == true then
			if util.is_valid(self.m_pSpeedSlider) == true then
				self.m_pSpeedSlider:SetValue(0)
			end
			local animComponent = ent:GetComponent(ents.COMPONENT_ANIMATED)
			if animComponent ~= nil then
				animComponent:SetCycle(pSlider:GetProgress())
			end
		end
	end)
	self.m_pFrameSlider = pFrameSlider

	local pLabelSpeed = gui.create("WIText", self)
	pLabelSpeed:SetText(locale.get_text("speed") .. ":")
	pLabelSpeed:SizeToContents()
	self.m_pLabelSpeed = pLabelSpeed

	local pSpeedSlider = gui.create("WISlider", self)
	pSpeedSlider:AddCallback("TranslateValue", function(pSlider, val)
		return val .. "%"
	end)
	pSpeedSlider:SetSize(256, 16)
	pSpeedSlider:SetRange(0, 150)
	pSpeedSlider:SetValue(100)
	pSpeedSlider:AddCallback("OnChange", function(pSlider, progress, value)
		if self:IsValid() == false then
			return
		end
		local ent = self:GetEntity()
		local animComponent = util.is_valid(ent) and ent:GetComponent(ents.COMPONENT_ANIMATED) or nil
		if animComponent ~= nil then
			animComponent:SetPlaybackRate(value / 100.0)
		end
	end)
	self.m_pSpeedSlider = pSpeedSlider

	self:SetSelectedAnimation()
	self:EnableThinking()
end
function gui.WIModelEditorAnimations:OnThink()
	local ent = self:GetEntity()
	if util.is_valid(self.m_pFrameSlider) == false or util.is_valid(ent) == false then
		return
	end
	local mdlComponent = ent:GetComponent(ents.COMPONENT_ANIMATED)
	local anim = self:GetSelectedAnimation()
	if mdlComponent == nil or anim == nil then
		return
	end
	local numFrames = anim:GetFrameCount()
	local frame = math.floor(mdlComponent:GetCycle() * (numFrames - 1))
	self.m_bUpdateCycle = false
	self.m_pFrameSlider:SetValue(frame)
	self.m_bUpdateCycle = nil
end
function gui.WIModelEditorAnimations:GetSelectedAnimation()
	return self.m_selectedAnimation
end
function gui.WIModelEditorAnimations:SetSelectedAnimation(anim)
	self.m_selectedAnimation = anim
	self:ShowControls((anim ~= nil) and true or false)
	local flags = (anim ~= nil) and anim:GetFlags() or 0
	local numFrames = (anim ~= nil) and (anim:GetFrameCount() - 1) or 0
	local fps = (anim ~= nil) and anim:GetFPS() or 0
	local act = (anim ~= nil) and anim:GetActivity() or Animation.ACT_INVALID
	local actWeight = (anim ~= nil) and anim:GetActivityWeight() or -1
	if util.is_valid(self.m_pCbLoop) == true then
		self.m_pCbLoop:SetChecked(bit.band(flags, Animation.FLAG_LOOP) ~= 0)
	end
	if util.is_valid(self.m_pCbNoRepeat) == true then
		self.m_pCbNoRepeat:SetChecked(bit.band(flags, Animation.FLAG_NOREPEAT) ~= 0)
	end
	if util.is_valid(self.m_pCbMoveX) == true then
		self.m_pCbMoveX:SetChecked(bit.band(flags, Animation.FLAG_MOVEX) ~= 0)
	end
	if util.is_valid(self.m_pCbMoveY) == true then
		self.m_pCbMoveY:SetChecked(bit.band(flags, Animation.FLAG_MOVEZ) ~= 0)
	end
	if util.is_valid(self.m_pCbAutoplay) == true then
		self.m_pCbAutoplay:SetChecked(bit.band(flags, Animation.FLAG_AUTOPLAY) ~= 0)
	end
	if util.is_valid(self.m_pCbGesture) == true then
		self.m_pCbGesture:SetChecked(bit.band(flags, Animation.FLAG_GESTURE) ~= 0)
	end
	if util.is_valid(self.m_pFrameSlider) == true then
		self.m_pFrameSlider:SetRange(0, numFrames)
	end
	if util.is_valid(self.m_pEventFrameSlider) == true then
		self.m_pEventFrameSlider:SetRange(0, numFrames)
	end
	if util.is_valid(self.m_pFPS) == true then
		self.m_pFPS:SetText(tostring(fps))
	end
	if util.is_valid(self.m_pActivity) == true then
		self.m_pActivity:SelectOption(tostring(act))
	end
	if util.is_valid(self.m_pActivityWeight) == true then
		self.m_pActivityWeight:SetText(tostring(actWeight))
	end
	if util.is_valid(self.m_pBlendController) == true then
		local text = ""
		local pEditor = self:GetEditor()
		local mdl = util.is_valid(pEditor) and pEditor:GetModel() or nil
		if util.is_valid(mdl) == true then
			local blendController = anim:GetBlendController()
			if blendController ~= nil then
				local bc = mdl:GetBlendController(blendController.controller)
				if bc ~= nil then
					text = bc.name
					-- TODO: min, max, loop
				end
			end
		end
		self.m_pBlendController:SetText(text)
	end
	self:ReloadEvents()
	self:ReloadBlendControllers()
end
function gui.WIModelEditorAnimations:ReloadBlendControllers()
	self.m_selectedEventIdx = nil
	if util.is_valid(self.m_pBlendControllers) == false then
		return
	end
	local pBlendControllers = self.m_pBlendControllers
	pBlendControllers:Clear()
	local pEditor = self:GetEditor()
	if util.is_valid(pEditor) == false then
		return
	end
	local mdl = pEditor:GetModel()
	if util.is_valid(mdl) == false then
		return
	end
	local anim = self:GetSelectedAnimation()
	if anim == nil then
		return
	end
	local bc = anim:GetBlendController()
	if bc == nil then
		return
	end
	for tId, t in ipairs(bc.transitions) do
		local pRow = pBlendControllers:AddRow()
		pRow:SetValue(0, mdl:GetAnimationName(t.animation))
		pRow:SetValue(1, tostring(t.transition))
	end
end
function gui.WIModelEditorAnimations:ReloadEvents()
	self.m_selectedEventIdx = nil
	if util.is_valid(self.m_pEvents) == false then
		return
	end
	local pEvents = self.m_pEvents
	pEvents:Clear()
	local anim = self:GetSelectedAnimation()
	if anim == nil then
		return
	end
	local events = anim:GetEvents()
	for frameId, frameEvents in pairs(events) do
		for evIdx, ev in ipairs(frameEvents) do
			local pRow = pEvents:AddRow()
			pRow:SetValue(0, tostring(frameId))

			pRow:SetValue(1, Animation.GetEventEnumName(ev.type) or tostring(ev.type))

			local args = ""
			for i, arg in ipairs(ev.arguments) do
				if i > 1 then
					args = args .. ", "
				end
				args = args .. arg
			end
			pRow:SetValue(2, args)

			pRow:AddCallback("OnSelected", function(pRow)
				if self:IsValid() == false then
					return
				end
				self.m_selectedEventIdx = evIdx - 1
				if util.is_valid(self.m_pEventFrameSlider) == true then
					self.m_pEventFrameSlider:SetValue(tonumber(pRow:GetValue(0)))
				end
				if util.is_valid(self.m_pType) == true then
					self.m_pType:SetText(pRow:GetValue(1))
				end
				if util.is_valid(self.m_pArguments) == true then
					self.m_pArguments:SetText(pRow:GetValue(2))
				end
			end)
		end
	end
end
function gui.WIModelEditorAnimations:AddFlag(name, fc, tooltip)
	if util.is_valid(self.m_pAnimGridPanel) == false then
		return
	end
	local pLb = gui.create("WIText")
	pLb:SetText(name)
	pLb:SizeToContents()
	local i = self.m_pAnimGridPanel:GetRowCount()

	local pCbOption = gui.create("WICheckbox")
	pCbOption:AddCallback("OnChange", fc)
	self.m_pAnimGridPanel:AddItem(pCbOption, i, 1)

	if tooltip ~= nil then
		pLb:SetTooltip(tooltip)
	end
	self.m_pAnimGridPanel:AddItem(pLb, i, 0)

	table.insert(self.m_tFlags, { pLb, pCbOption })
	return pCbOption
end
function gui.WIModelEditorAnimations:SetModel(mdl)
	local pAnimations = self.m_pAnimations
	if util.is_valid(pAnimations) == false then
		return
	end
	pAnimations:Clear()

	if util.is_valid(mdl) == false then
		return
	end
	local tAnims = mdl:GetAnimationNames()
	table.sort(tAnims)
	for _, anim in ipairs(tAnims) do
		local pRow = pAnimations:AddRow()
		pRow:AddCallback("OnSelected", function(pRow)
			if self:IsValid() == false then
				return
			end
			local pCell = pRow:GetCell(0)
			if util.is_valid(pCell) == false then
				return
			end
			local pText = pCell:GetFirstChild("WIText")
			if util.is_valid(pText) == false then
				return
			end
			local animName = pText:GetText()
			local anim = mdl:GetAnimation(animName)
			if anim == nil then
				return
			end
			self:SetSelectedAnimation(anim)
			self:CallCallbacks("OnAnimationSelected", animName)
		end)
		pRow:SetValue(0, anim)
	end
	pAnimations:Resize()
end
function gui.WIModelEditorAnimations:ShowControls(b)
	if util.is_valid(self.m_pAnimGridPanel) == true then
		self.m_pAnimGridPanel:SetVisible(b)
	end
	if util.is_valid(self.m_pEventContainer) == true then
		self.m_pEventContainer:SetVisible(b)
	end
	if util.is_valid(self.m_pBlendControllerContainer) == true then
		self.m_pBlendControllerContainer:SetVisible(b)
	end
	if util.is_valid(self.m_pFrameSlider) == true then
		self.m_pFrameSlider:SetVisible(b)
	end
	if util.is_valid(self.m_pLabelFrame) == true then
		self.m_pLabelFrame:SetVisible(b)
	end
	if util.is_valid(self.m_pSpeedSlider) == true then
		self.m_pSpeedSlider:SetVisible(b)
	end
	if util.is_valid(self.m_pLabelSpeed) == true then
		self.m_pLabelSpeed:SetVisible(b)
	end
end
function gui.WIModelEditorAnimations:OnSizeChanged(w, h)
	gui.Base.OnSizeChanged(self, w, h)

	if util.is_valid(self.m_pAnimations) == false then
		return
	end

	local x = MARGIN_OFFSET
	local y = self.m_pAnimations:GetHeight() + MARGIN_OFFSET
	for _, p in ipairs({ self.m_pAnimGridPanel, self.m_pEventContainer, self.m_pBlendControllerContainer }) do
		p:SetPos(MARGIN_OFFSET, y)
		p:SizeToContents()
		p:SetWidth(600)
	end
	if util.is_valid(self.m_pTabPanel) == false then
		return
	end
	self.m_pTabPanel:SetSize(w, h - 80)
	y = self.m_pTabPanel:GetHeight() + MARGIN_OFFSET
	if util.is_valid(self.m_pFrameSlider) == true then
		local x = MARGIN_OFFSET
		if util.is_valid(self.m_pLabelFrame) == true then
			self.m_pLabelFrame:SetPos(x, y)
			x = self.m_pLabelFrame:GetX() + self.m_pLabelFrame:GetWidth() + MARGIN_OFFSET * 0.5
		end
		self.m_pFrameSlider:SetPos(x, y)
		y = y + self.m_pFrameSlider:GetHeight()
	end
	if util.is_valid(self.m_pSpeedSlider) == true then
		local x = MARGIN_OFFSET
		if util.is_valid(self.m_pLabelSpeed) == true then
			self.m_pLabelSpeed:SetPos(x, y)
			x = self.m_pLabelSpeed:GetX() + self.m_pLabelSpeed:GetWidth() + MARGIN_OFFSET * 0.5
		end
		self.m_pSpeedSlider:SetPos(x, y)
		y = y + self.m_pSpeedSlider:GetHeight()
	end
end
gui.register("model_editor_animations", gui.WIModelEditorAnimations)
