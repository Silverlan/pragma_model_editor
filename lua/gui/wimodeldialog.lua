-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/wifileexplorer.lua")
include("/gui/editors/model_editor/wimodelviewer.lua")
include("/gui/dialog.lua")
include("/gui/pfm/catalogs/model_catalog.lua")

util.register_class("gui.WIModelDialog", gui.Base)

function gui.WIModelDialog:__init()
	gui.Base.__init(self)
end
function gui.WIModelDialog:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(1210, 781)

	local bg = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	bg:SetColor(Color.DimGray)

	local titleBar = gui.create("WIRect", self, 0, 0, self:GetWidth(), 31, 0, 0, 1, 0)
	titleBar:SetColor(Color.White)

	local title = gui.create("WIText", titleBar)
	title:SetColor(Color.Black)
	title:SetText(locale.get_text("mde_select_model"))
	title:SizeToContents()
	title:CenterToParentY()
	title:SetX(10)

	local x = 12
	local y = 60
	local contents = gui.create("hbox", self, x, y, self:GetWidth() - x * 2, self:GetHeight() - y * 2, 0, 0, 1, 1)
	contents:SetAutoFillContents(true)
	self.m_contents = contents

	local pTabPanel = gui.create("tabbed_panel", contents)
	pTabPanel:AddCallback("OnTabSelected", function(pTabbedPanel, pTab, pPanel)
		--[[if(self:IsValid() == false) then return end
		self.m_pSelectedTab = pPanel
		for idx,pOther in ipairs(self.m_tPanels) do
			if(util.is_valid(pOther) == true) then
				local b = (pPanel == pOther:GetParent()) and true or false
				pOther:SetShowItems(b or self.m_tShowPanel[idx])
				pOther:SetSelected(b)
			end
		end]]
	end)

	local tabMdlExplorer = pTabPanel:AddTab(locale.get_text("mde_model_explorer"))
	tabMdlExplorer:SetSize(592, 497)

	local mdlCatalog = gui.create(
		"pfm_model_catalog",
		tabMdlExplorer,
		0,
		0,
		tabMdlExplorer:GetWidth(),
		tabMdlExplorer:GetHeight(),
		0,
		0,
		1,
		1
	)
	local explorer = mdlCatalog:GetExplorer()
	explorer:AddCallback("OnIconAdded", function(explorer, icon)
		if icon:IsDirectory() == false then
			icon:AddCallback("OnSelectionChanged", function(icon, selected)
				if icon:IsNativeAsset() == false then
					icon:Reload(true)
				end
				local mdlPath = util.Path(icon:GetAsset())
				mdlPath:PopFront()
				self:SetModel(mdlPath:GetString())
				return util.EVENT_REPLY_HANDLED
			end)
			icon:AddCallback("OnDoubleClick", function(icon)
				self:CallCallbacks("OnFileSelected", self:GetModelName())
				self:Close(gui.DIALOG_RESULT_OK)
			end)
		end
	end)
	self.m_pFileList = mdlCatalog

	--[[local t = gui.create("file_explorer",tabMdlExplorer,0,0,tabMdlExplorer:GetWidth(),tabMdlExplorer:GetHeight(),0,0,1,1)
	t:SetRootPath("models")
	t:SetExtensions({"wmd"})
	t:AddCallback("OnFileClicked",function(p,fName)
		if(util.is_valid(self) == false or util.is_valid(self.m_mdlViewer) == false) then return end
		local path = t:GetAbsolutePath() .. fName
		path = file.remove_file_extension(path:sub(8))
		self:SetModel(path)
	end)
	t:AddCallback("OnFileSelected",function(p,fPath)
		self:CallCallbacks("OnFileSelected",self:GetModelName())
		self:Close(gui.DIALOG_RESULT_OK)
	end)
	t:Update()
	self.m_pFileList = t]]

	self:InitializeAssetImporter(pTabPanel, tabMdlExplorer)

	local resizer = gui.create("resizer", contents)

	local mdlViewer = gui.create("model_viewer", contents)
	self.m_mdlViewer = mdlViewer

	local buttonContainer = gui.create("hbox", self)
	local btOpen = gui.create("WIButton", buttonContainer)
	btOpen:SetText(locale.get_text("open"))
	btOpen:AddCallback("OnPressed", function()
		self:CallCallbacks("OnFileSelected", self:GetModelName())
		self:Close(gui.DIALOG_RESULT_OK)
	end)

	gui.create("WIBase", buttonContainer, 0, 0, 8, 1) -- gap

	local btCancel = gui.create("WIButton", buttonContainer)
	btCancel:SetText(locale.get_text("cancel"))
	btCancel:AddCallback("OnPressed", function()
		if self.m_fResultHandler ~= nil then
			self.m_fResultHandler(gui.DIALOG_RESULT_CANCELLED)
		end
		self:Close(gui.DIALOG_RESULT_CANCELLED)
	end)
	buttonContainer:Update()
	buttonContainer:SetPos(contents:GetRight() - buttonContainer:GetWidth(), contents:GetBottom() + 10)
	buttonContainer:SetAnchor(1, 1, 1, 1)

	resizer:SetFraction(0.45)
end
function gui.WIModelDialog:InitializeAssetImporter(pTabPanel, tabMdlExplorer)
	local tabAssetImporter = pTabPanel:AddTab(locale.get_text("mde_asset_importer"))
	tabAssetImporter:SetSize(tabMdlExplorer:GetSize())

	local vbox = gui.create("vbox", tabAssetImporter)
	gui.create("WIBase", vbox, 0, 0, 1, 8) -- gap
	local buttonContainer = gui.create("hbox", vbox)
	local btImport = gui.create("WIButton", buttonContainer)
	btImport:SetText(locale.get_text("import"))
	btImport:SizeToContents()
	gui.create("WIBase", buttonContainer, 0, 0, 8, 1) -- gap
	buttonContainer:Update()
	gui.create("WIBase", vbox, 0, 0, 1, 8) -- gap
	vbox:Update()

	local tAssetExplorer = gui.create(
		"file_explorer",
		tabAssetImporter,
		0,
		0,
		tabAssetImporter:GetWidth(),
		tabAssetImporter:GetHeight() - vbox:GetHeight(),
		0,
		0,
		1,
		1
	)
	tAssetExplorer:SetRootPath("")
	tAssetExplorer:SetExtensions({ "fbx", "pmx" })
	tAssetExplorer:Update()
	self.m_pAssetExplorer = tAssetExplorer

	btImport:AddCallback("OnPressed", function()
		local fileName = tAssetExplorer:GetSelectedFile()
		self:ImportModel(fileName)
	end)

	vbox:SetPos(tabAssetImporter:GetWidth() - vbox:GetWidth(), tAssetExplorer:GetBottom())
	vbox:SetAnchor(1, 1, 1, 1)
end
function gui.WIModelDialog:ImportModel(fileName)
	local f = file.open(fileName, bit.bor(file.OPEN_MODE_READ, file.OPEN_MODE_BINARY))
	if f == nil then
		return
	end
	local ext = file.get_file_extension(fileName)
	local mdl
	-- TODO: Streamline this and allow custom importers
	local mdlName = file.get_file_name(file.remove_file_extension(fileName))
	if ext == "pmx" then
		local r = engine.load_library("mmd/pr_mmd")
		if r ~= true then
			console.print_warning("Unable to load MikuMikuDance module: " .. r)
			return
		end
		mdl = game.create_model(mdlName)
		local success = import.import_pmx(f, mdl)
		f:Close()
		if success == false then
			return
		end

		-- Attempt to import textures as well
		local texturePath = file.get_file_path(fileName) -- TODO: Use whichever directories are selected as texture path?
		asset.import_material_textures(mdl, { texturePath })
	else
		local subMeshes, textures = import.import_model_asset(f)
		f:Close()
		if subMeshes == nil then
			return
		end

		print("Number of meshes found: ", #subMeshes)
		print("Number of textures used by model: ", #textures)
		print("Generating model...")
		mdl = game.create_model(mdlName)
		local meshGroup = mdl:GetMeshGroup(0)

		local mesh = game.Model.Mesh.Create()
		for _, subMesh in ipairs(subMeshes) do
			mesh:AddSubMesh(subMesh)
			print(
				"Added mesh with "
					.. subMesh:GetVertexCount()
					.. " vertices and "
					.. subMesh:GetTriangleCount()
					.. " triangles."
			)
		end
		meshGroup:AddMesh(mesh)

		local matPath = "models/" .. mdlName .. "/"
		print("Adding material path " .. matPath)
		for _, tex in ipairs(textures) do
			local texPath = matPath .. tex
			local mat = asset.generate_material(texPath, {
				albedoMap = texPath,
			})
			print("Adding albedo map " .. texPath)
			mdl:AddMaterial(0, mat)
		end

		local texturePath = file.get_file_path(fileName) -- TODO: Use whichever directories are selected as texture path?
		print("Importing with texture path " .. texturePath)
		asset.import_material_textures(mdl, { texturePath })

		-- Assign white material to any meshes that don't have a valid material
		local numMats = mdl:GetMaterialCount()
		print("Mat Count: ", numMats)
		local matWhiteIdx
		for _, subMesh in ipairs(subMeshes) do
			local matIdx = subMesh:GetSkinTextureIndex()
			print("Mesh mat idx: ", matIdx)
			if matIdx >= numMats then
				if matWhiteIdx == nil then
					local matWhite = game.load_material("white")
					matWhiteIdx = mdl:AddMaterial(0, matWhite)
					numMats = mdl:GetMaterialCount()
				end
				print("Assigning white material...", matWhiteIdx)
				subMesh:SetSkinTextureIndex(matWhiteIdx)
			end
		end
	end
	mdl:Update(game.Model.FUPDATE_ALL)
	self:SetModel(mdl)
end
function gui.WIModelDialog:Close(result)
	gui.close_dialog()
	if self.m_fResultHandler == nil then
		return
	end
	if result == gui.DIALOG_RESULT_OK then
		local mdlName = self:GetModelName()
		if mdlName == nil then
			self.m_fResultHandler(gui.DIALOG_RESULT_NO_SELECTION)
		else
			self.m_fResultHandler(gui.DIALOG_RESULT_OK, mdlName)
		end
		return
	end
	self.m_fResultHandler(result)
end
function gui.WIModelDialog:SetResultHandler(fResultHandler)
	self.m_fResultHandler = fResultHandler
end
function gui.WIModelDialog:GetModelName()
	return self.m_modelName
end
function gui.WIModelDialog:SetModel(modelName)
	if type(modelName) == "string" then
		self.m_modelName = modelName
		self.m_mdlViewer:SetModel(modelName)
		return
	end
	self.m_modelName = "import"
	self.m_mdlViewer:SetModel(modelName)
end
gui.register("model_dialog", gui.WIModelDialog)

gui.open_model_dialog = function(resultHandler)
	return gui.create_dialog(function()
		local el = gui.create("model_dialog")
		el:SetResultHandler(resultHandler)
		return el
	end)
end
