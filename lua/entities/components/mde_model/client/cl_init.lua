util.register_class("ents.MdeModelPreviewComponent", BaseEntityComponent)

function ents.MdeModelPreviewComponent:__init()
	BaseEntityComponent.__init(self)
end

function ents.MdeModelPreviewComponent:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_ANIMATED)

	self:BindEvent(ents.AnimatedComponent.EVENT_HANDLE_ANIMATION_EVENT, "HandleAnimationEvent")

	self.m_selectedBones = {}
	self:SetShouldPlaySounds(false)
	self:SetShouldShowMovement(false)
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end

function ents.MdeModelPreviewComponent:SetBoneSelected(boneId, selected)
	self.m_selectedBones[boneId] = selected or nil
end

function ents.MdeModelPreviewComponent:GetSelectedBones()
	return self.m_selectedBones
end

function ents.MdeModelPreviewComponent:SetShouldPlaySounds(b)
	self.m_bShouldPlaySounds = b
end
function ents.MdeModelPreviewComponent:SetShouldShowMovement(b)
	self.m_bShouldShowMovement = b
end

function ents.MdeModelPreviewComponent:OnTick(dt)
	local ent = self:GetEntity()
	local trComponent = ent:GetComponent(ents.COMPONENT_TRANSFORM)
	local mdlComponent = ent:GetComponent(ents.COMPONENT_MODEL)
	local animComponent = ent:GetComponent(ents.COMPONENT_ANIMATED)
	if trComponent == nil or mdlComponent == nil or animComponent == nil then
		return
	end
	if animComponent:GetCycle() == 1.0 then
		animComponent:SetCycle(0.0)
	end
	local pos = Vector()
	if self.m_bShouldShowMovement == true then
		local mdl = mdlComponent:GetModel()
		if mdl ~= nil then
			local animId = animComponent:GetAnimation()
			local anim = mdl:GetAnimation(animId)
			if anim ~= nil then
				local flags = anim:GetFlags()
				if bit.band(flags, Animation.FLAG_MOVEX) ~= 0 or bit.band(flags, Animation.FLAG_MOVEZ) ~= 0 then
					local cycle = animComponent:GetCycle()
					local curFrame = animComponent:GetCycle() * (anim:GetFrameCount() - 1)
					local frameId = math.floor(curFrame)
					local offset = Vector()
					local rot = trComponent:GetRotation()
					rot:Inverse()

					local tFrame = 1 / anim:GetFPS()
					for i = 0, frameId do
						local frame = anim:GetFrame(i)
						local x, z = frame:GetMoveTranslation()
						offset = offset + Vector(x, 0, -z) * tFrame
					end

					local nextFrame = anim:GetFrame(frameId + 1)
					if nextFrame ~= nil then
						curFrame = curFrame - frameId
						local x, z = nextFrame:GetMoveTranslation()
						offset = offset + Vector(x, 0, -z) * tFrame * curFrame
					end

					offset = offset * rot
					pos = pos + offset
				end
			end
		end
	end
	--trComponent:SetPos(pos)
end

function ents.MdeModelPreviewComponent:HandleAnimationEvent(evId, args)
	if evId == Animation.EVENT_FOOTSTEP_LEFT or evId == Animation.EVENT_FOOTSTEP_RIGHT then
		if self.m_bShouldPlaySounds == true then
			sound.play("fx.fst_concrete", bit.bor(sound.TYPE_EFFECT, sound.TYPE_GUI), 1.0, 1.0)
		end
		return util.EVENT_REPLY_HANDLED
	elseif evId == Animation.EVENT_EMITSOUND then
		if #args > 0 and self.m_bShouldPlaySounds == true then
			sound.play(args[1], bit.bor(sound.TYPE_EFFECT, sound.TYPE_GUI), 1.0, 1.0)
		end
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
ents.COMPONENT_MDE_MODEL_PREVIEW = ents.register_component("mde_model", ents.MdeModelPreviewComponent)
