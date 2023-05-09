util.register_class("gui.WIModelEditorBlendControllers", gui.Base, gui.WIModelEditorPanel)
local MARGIN_OFFSET = 20

function gui.WIModelEditorBlendControllers:__init()
	gui.Base.__init(self)
	gui.WIModelEditorPanel.__init(self)
end
function gui.WIModelEditorBlendControllers:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_activeBlendController = ""
	local pBlendControllers = gui.create("WITable", self)
	pBlendControllers:SetHeight(186)
	pBlendControllers:SetAutoAlignToParent(true, false)
	pBlendControllers:SetScrollable(true)
	pBlendControllers:SetSelectableMode(gui.Table.SELECTABLE_MODE_SINGLE)
	pBlendControllers:SetRowHeight(20)
	local pHeader = pBlendControllers:AddHeaderRow()
	pHeader:SetValue(0, locale.get_text("name"))
	pHeader:SetValue(1, locale.get_text("min"))
	pHeader:SetValue(2, locale.get_text("max"))
	pHeader:SetValue(3, locale.get_text("loop"))
	pHeader:SetValue(4, locale.get_text("current_value"))
	self.m_pBlendControllers = pBlendControllers

	local pLbActiveController = gui.create("WIText", self)
	pLbActiveController:SetText(locale.get_text("active_blend_controller") .. ":")
	pLbActiveController:SizeToContents()
	self.m_pLbActiveController = pLbActiveController

	local pLbCurrentValue = gui.create("WIText", self)
	pLbCurrentValue:SetText(locale.get_text("current_value") .. ": ")
	pLbCurrentValue:SizeToContents()
	self.m_pLbCurrentValue = pLbCurrentValue

	local pSlider = gui.create("WISlider", self)
	pSlider:SetSize(256, 16)
	pSlider:AddCallback("TranslateValue", function(pSlider, val)
		return val
	end)
	pSlider:AddCallback("OnChange", function(pSlider, progress, value)
		if self:IsValid() == false or #self.m_activeBlendController == 0 then
			return
		end
		self:CallCallbacks("OnBlendControllerChanged", self.m_activeBlendController, value)
		if util.is_valid(pBlendControllers) == false then
			return
		end
		local pRow = pBlendControllers:GetFirstSelectedRow()
		if util.is_valid(pRow) == false then
			return
		end
		pRow:SetValue(4, tostring(value))
	end)
	self.m_pSlider = pSlider

	local pButtonReset = gui.create("WIButton", self)
	pButtonReset:SetText(locale.get_text("reset"))
	pButtonReset:SizeToContents()
	pButtonReset:AddCallback("OnPressed", function(pButtonReset)
		if self:IsValid() == false then
			return
		end
		self:Reset()
	end)
	self.m_pButtonReset = pButtonReset

	self:ShowControls(false)
end
function gui.WIModelEditorBlendControllers:Render(drawCmd, cam)
	local pEditor = self:GetEditor()
	if util.is_valid(pEditor) == false then
		return
	end
end
function gui.WIModelEditorBlendControllers:ShowControls(b)
	if util.is_valid(self.m_pLbActiveController) == true then
		self.m_pLbActiveController:SetVisible(b)
	end
	if util.is_valid(self.m_pLbCurrentValue) == true then
		self.m_pLbCurrentValue:SetVisible(b)
	end
	if util.is_valid(self.m_pSlider) == true then
		self.m_pSlider:SetVisible(b)
	end
end
function gui.WIModelEditorBlendControllers:Reset()
	if util.is_valid(self.m_pSlider) == true then
		self.m_pSlider:SetValue(0)
	end
	if util.is_valid(self.m_model) == true then
		for _, blendController in ipairs(self.m_model:GetBlendControllers()) do
			self:CallCallbacks("OnBlendControllerChanged", blendController.name, 0.0)
		end
	end
	if util.is_valid(self.m_pBlendControllers) == false then
		return
	end
	for _, pRow in ipairs(self.m_pBlendControllers:GetRows()) do
		pRow:SetValue(4, "0.0")
	end
end
function gui.WIModelEditorBlendControllers:SetActiveBlendController(bc)
	if bc == self.m_activeBlendController then
		return
	end
	self.m_activeBlendController = bc
	if util.is_valid(self.m_pSlider) == false then
		return
	end
	if util.is_valid(self.m_model) == true and util.is_valid(self.m_pBlendControllers) == true then
		local blendController = self.m_model:GetBlendController(bc)
		if blendController ~= nil then
			local pRow = self.m_pBlendControllers:GetFirstSelectedRow()
			if util.is_valid(pRow) == true then
				self:ShowControls(true)
				self.m_pSlider:SetRange(blendController.min, blendController.max)
				self.m_pSlider:SetValue(tonumber(pRow:GetValue(4)))
				if util.is_valid(self.m_pLbActiveController) == true then
					self.m_pLbActiveController:SetText(
						locale.get_text("active_blend_controller") .. ": " .. blendController.name
					)
					self.m_pLbActiveController:SizeToContents()
				end
				return
			end
		end
	end
	self:ShowControls(false)
end
function gui.WIModelEditorBlendControllers:SetModel(mdl)
	self.m_model = mdl
	local pBlendControllers = self.m_pBlendControllers
	if util.is_valid(pBlendControllers) == false then
		return
	end
	pBlendControllers:Clear()

	if util.is_valid(mdl) == false then
		return
	end
	local blendControllers = mdl:GetBlendControllers()
	for _, blendController in ipairs(blendControllers) do
		local pRow = pBlendControllers:AddRow()
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
			self:SetActiveBlendController(pText:GetText())
		end)
		pRow:SetValue(0, blendController.name)
		pRow:SetValue(1, tostring(blendController.min))
		pRow:SetValue(2, tostring(blendController.max))
		pRow:SetValue(3, (blendController.loop == true) and locale.get_text("yes") or locale.get_text("no"))
		pRow:SetValue(4, "0.0")
	end
end
function gui.WIModelEditorBlendControllers:OnSizeChanged(w, h)
	gui.Base.OnSizeChanged(self, w, h)

	if util.is_valid(self.m_pBlendControllers) == false then
		return
	end
	local yOffset = self.m_pBlendControllers:GetY() + self.m_pBlendControllers:GetHeight()
	local x = MARGIN_OFFSET
	local y = yOffset
	if util.is_valid(self.m_pLbActiveController) == true then
		self.m_pLbActiveController:SetPos(MARGIN_OFFSET, y + MARGIN_OFFSET)
		y = self.m_pLbActiveController:GetY() + self.m_pLbActiveController:GetHeight()
	end
	if util.is_valid(self.m_pLbCurrentValue) == true then
		self.m_pLbCurrentValue:SetPos(MARGIN_OFFSET, y)
		x = self.m_pLbCurrentValue:GetX() + self.m_pLbCurrentValue:GetWidth()
	end
	if util.is_valid(self.m_pSlider) == true then
		self.m_pSlider:SetPos(x, y)
	end
	if util.is_valid(self.m_pButtonReset) == false then
		return
	end
	self.m_pButtonReset:SetPos(w - self.m_pButtonReset:GetWidth() - MARGIN_OFFSET, yOffset + MARGIN_OFFSET)
end
gui.register("WIModelEditorBlendControllers", gui.WIModelEditorBlendControllers)
