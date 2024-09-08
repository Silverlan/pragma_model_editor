util.register_class("shader.MdeTextured", shader.BasePbr)

shader.MdeTextured.FragmentShader = "programs/mde/textured"
shader.MdeTextured.VertexShader = "programs/scene/textured"
function shader.MdeTextured:__init()
	shader.BasePbr.__init(self)
end

function shader.MdeTextured:Draw(mesh)
	shader.BasePbr.Draw(self, mesh)
end
shader.register("mde_textured", shader.MdeTextured)
