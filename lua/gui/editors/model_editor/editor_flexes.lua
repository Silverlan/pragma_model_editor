-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("gui.WIModelEditorFlexes", gui.Base, gui.WIModelEditorPanel)

local MARGIN_OFFSET = 20

function gui.WIModelEditorFlexes:__init()
	gui.Base.__init(self)
	gui.WIModelEditorPanel.__init(self)
end
function gui.WIModelEditorFlexes:OnInitialize()
	gui.Base.OnInitialize(self)

	local pFlexControllers = gui.create("WITable", self)
	pFlexControllers:SetAutoAlignToParent(true, false)
	pFlexControllers:SetScrollable(true)
	pFlexControllers:SetSelectableMode(gui.Table.SELECTABLE_MODE_SINGLE)
	pFlexControllers:SetRowHeight(20)
	local pHeader = pFlexControllers:AddHeaderRow()
	pHeader:SetValue(0, locale.get_text("id"))
	pHeader:SetValue(1, locale.get_text("name"))
	pHeader:SetValue(2, locale.get_text("min"))
	pHeader:SetValue(3, locale.get_text("max"))
	pHeader:SetValue(4, locale.get_text("value"))
	self.m_pFlexControllers = pFlexControllers

	local pFlexes = gui.create("WITable", self)
	pFlexes:SetAutoAlignToParent(true, false)
	pFlexes:SetScrollable(true)
	pFlexes:SetSelectableMode(gui.Table.SELECTABLE_MODE_SINGLE)
	pFlexes:SetRowHeight(20)
	local pHeaderFlex = pFlexes:AddHeaderRow()
	pHeaderFlex:SetValue(0, locale.get_text("id"))
	pHeaderFlex:SetValue(1, locale.get_text("name"))
	pHeaderFlex:SetValue(2, locale.get_text("formula"))
	pHeaderFlex:SetValue(3, locale.get_text("value"))
	self.m_pFlexes = pFlexes

	self.m_tOptions = {}
	self.m_tFlexSliders = {}
end
function gui.WIModelEditorFlexes:AddFlexController(idx, name, min, max)
	local mdl = self:GetEditor():GetModel()
	local pFlexControllers = self.m_pFlexControllers
	local pRow = pFlexControllers:AddRow()
	pRow:SetValue(0, tostring(idx))
	pRow:SetValue(1, name)
	pRow:SetValue(2, tostring(min))
	pRow:SetValue(3, tostring(max))

	local pSlider = gui.create("WISlider")
	pSlider:SetSize(256, 16)
	pSlider:SetRange(0.0, 1.0, 0.01)
	pSlider:AddCallback("OnChange", function(pSlider, progress, value)
		local ent = self:GetEntity()
		if util.is_valid(ent) == false then
			return
		end
		local flexComponent = ent:AddComponent(ents.COMPONENT_FLEX)
		local vertexAnimComponent = ent:AddComponent(ents.COMPONENT_VERTEX_ANIMATED)
		if flexComponent == nil or vertexAnimComponent == nil then
			return
		end
		flexComponent:SetFlexController(name, value)
		self:UpdateFlexSliders()
		self:GetEditor():ScheduleEntityForRendering()
	end)
	local ent = self:GetEntity()
	local flexComponent = util.is_valid(ent) and ent:GetComponent(ents.COMPONENT_FLEX) or nil
	if flexComponent ~= nil then
		pSlider:SetValue(flexComponent:GetFlexController(name) or 0.0)
	end
	pRow:InsertElement(4, pSlider)

	pRow:AddCallback("OnSelected", function(pRow)
		if self:IsValid() == false then
			return
		end
	end)
	return pRow
end
function gui.WIModelEditorFlexes:UpdateFlexSliders()
	local ent = self:GetEntity()
	if util.is_valid(ent) == false then
		return
	end
	local flexComponent = ent:GetComponent(ents.COMPONENT_FLEX)
	for flexId, pSlider in pairs(self.m_tFlexSliders) do
		if pSlider:IsValid() == true then
			pSlider:SetValue(flexComponent:CalcFlexValue(flexId) or 0.0)
		end
	end
end
function gui.WIModelEditorFlexes:AddFlex(idx, name)
	local mdl = self:GetEditor():GetModel()
	local pFlexes = self.m_pFlexes
	local pRow = pFlexes:AddRow()
	pRow:SetValue(0, tostring(idx))
	pRow:SetValue(1, name)
	pRow:SetValue(2, (mdl ~= nil) and mdl:GetFlexFormula(name) or "")

	local pSlider = gui.create("WIProgressBar")
	pSlider:SetSize(256, 16)
	pSlider:SetRange(0.0, 1.0, 0.01)
	pSlider:AddCallback("OnChange", function(pSlider, progress, value)
		--[[local ent = self:GetEntity()
		if(util.is_valid(ent) == false) then return end
		local flexComponent = ent:AddComponent(ents.COMPONENT_FLEX)
		local vertexAnimComponent = ent:AddComponent(ents.COMPONENT_VERTEX_ANIMATED)
		if(flexComponent == nil or vertexAnimComponent == nil) then return end
		flexComponent:SetFlexController(name,value)
		
		self:GetEditor():ScheduleEntityForRendering()]]
	end)
	local ent = self:GetEntity()
	local flexComponent = util.is_valid(ent) and ent:GetComponent(ents.COMPONENT_FLEX) or nil
	local flexId = (mdl ~= nil) and mdl:LookupFlex(name) or -1
	if flexComponent ~= nil and flexId ~= -1 then
		pSlider:SetValue(flexComponent:CalcFlexValue(flexId) or 0.0)
	end
	self.m_tFlexSliders[flexId] = pSlider
	pRow:InsertElement(3, pSlider)

	pRow:AddCallback("OnSelected", function(pRow)
		if self:IsValid() == false then
			return
		end
	end)
	return pRow
end
--[[function gui.WIModelEditorFlexes:AddFlex(name)
	local pLb = gui.create("WIText",self)
	pLb:SetText(name)
	pLb:SizeToContents()
	
	local pSlider = gui.create("WISlider",self)
	pSlider:SetSize(256,16)
	pSlider:SetRange(0.0,1.0,0.01)
	pSlider:AddCallback("OnChange",function(pSlider,progress,value)
		local ent = self:GetEntity()
		if(util.is_valid(ent) == false) then return end
		local flexComponent = ent:AddComponent(ents.COMPONENT_FLEX)
		local vertexAnimComponent = ent:AddComponent(ents.COMPONENT_VERTEX_ANIMATED)
		if(flexComponent == nil or vertexAnimComponent == nil) then return end
		flexComponent:SetFlexController(name,value)
		
		self:GetEditor():ScheduleEntityForRendering()
	end)
	local ent = self:GetEntity()
	local flexComponent = ent:GetComponent(ents.COMPONENT_FLEX)
	if(flexComponent ~= nil) then
		pSlider:SetValue(0.0)
	end
	self.m_pSlider = pSlider
	
	table.insert(self.m_tOptions,{pLb,pSlider})
	return pSlider
end]]
function gui.WIModelEditorFlexes:OnSizeChanged(w, h)
	gui.Base.OnSizeChanged(self, w, h)
	self:UpdateOptions()
end
function gui.WIModelEditorFlexes:UpdateOptions()
	local w = self:GetWidth()
	local x = 15
	local height = self:GetHeight()
	if util.is_valid(self.m_pFlexControllers) == true then
		self.m_pFlexControllers:SetHeight(height * 0.4)
	end
	if util.is_valid(self.m_pFlexes) == true then
		self.m_pFlexes:SetHeight(height * 0.4)
		if util.is_valid(self.m_pFlexControllers) == true then
			self.m_pFlexes:SetY(self.m_pFlexControllers:GetBottom() + 10)
		end
	end
	local yStart = MARGIN_OFFSET
	if util.is_valid(self.m_pFlexControllers) then
		yStart = yStart + self.m_pFlexControllers:GetBottom()
	end
	local y = yStart
	for idx, t in ipairs(self.m_tOptions) do
		if util.is_valid(t[1]) == true and util.is_valid(t[2]) == true then
			local yNew = y + t[1]:GetHeight()
			if yNew > height then
				x = x + t[2]:GetWidth() + 20
				y = yStart
				yNew = y + t[1]:GetHeight()
			end
			t[1]:SetPos(x, y)
			t[2]:SetPos(t[1]:GetX(), yNew)
			y = t[2]:GetY() + t[2]:GetHeight()
		end
	end
end
function gui.WIModelEditorFlexes:SetModel(mdl)
	if mdl == nil then
		return
	end
	local ent = self:GetEntity()
	local pEditor = self:GetEditor()

	if util.is_valid(self.m_pFlexControllers) then
		self.m_pFlexControllers:Clear()
	end
	if util.is_valid(self.m_pFlexes) then
		self.m_pFlexes:Clear()
	end
	self.m_tOptions = {}
	self.m_tFlexSliders = {}
	for idx, flexController in ipairs(mdl:GetFlexControllers()) do
		self:AddFlexController(idx - 1, flexController.name, flexController.min, flexController.max)
	end
	for idx, flex in ipairs(mdl:GetFlexes()) do
		self:AddFlex(idx, flex:GetName())
	end
	self:UpdateOptions()
end
gui.register("model_editor_flexes", gui.WIModelEditorFlexes)
