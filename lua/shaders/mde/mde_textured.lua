util.register_class("shader.MdeTextured",shader.BasePbr)

shader.MdeTextured.FragmentShader = "mde/fs_mde_textured"
shader.MdeTextured.VertexShader = "world/vs_textured"
function shader.MdeTextured:__init()
	shader.BasePbr.__init(self)
end

function shader.MdeTextured:Draw(mesh)
	shader.BasePbr.Draw(self,mesh)
end
shader.register("mde_textured",shader.MdeTextured)
