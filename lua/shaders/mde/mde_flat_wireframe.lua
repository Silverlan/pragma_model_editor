include("mde_flat.lua")

util.register_class("shader.MdeFlatWireframe",shader.MdeFlat)

function shader.MdeFlatWireframe:__init()
	shader.MdeFlat.__init(self)
end
function shader.MdeFlatWireframe:InitializePipeline(pipelineInfo,pipelineIdx)
  shader.MdeFlat.InitializePipeline(self,pipelineInfo,pipelineIdx)
  pipelineInfo:SetDynamicStateEnabled(prosper.DYNAMIC_STATE_LINE_WIDTH_BIT,true)
  pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_LINE)
end
function shader.MdeFlatWireframe:OnPrepareDraw(drawCmd)
	shader.MdeFlat.OnPrepareDraw(self,drawCmd)
	drawCmd:RecordSetLineWidth(2.0)
end
shader.register("mde_flat_wireframe",shader.MdeFlatWireframe)
