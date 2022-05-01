util.register_class("gui.WIModelEditorPanel")

function gui.WIModelEditorPanel:__init()
	self.m_bShowItems = false
	self.m_bSelected = false
end
function gui.WIModelEditorPanel:SetShowItems(b) self.m_bShowItems = b end
function gui.WIModelEditorPanel:GetShowItems() return self.m_bShowItems end
function gui.WIModelEditorPanel:SetSelected(b) self.m_bSelected = b end
function gui.WIModelEditorPanel:IsSelected() return self.m_bSelected end
function gui.WIModelEditorPanel:SetEntity(ent) self.m_entity = ent end
function gui.WIModelEditorPanel:GetEntity() return self.m_entity end
function gui.WIModelEditorPanel:SetEditor(pEditor) self.m_pEditor = pEditor end
function gui.WIModelEditorPanel:GetEditor() return self.m_pEditor end
function gui.WIModelEditorPanel:SetModel(mdl) end
function gui.WIModelEditorPanel:Render(drawCmd,cam) end
function gui.WIModelEditorPanel:PrepareRendering(pModelView) end
