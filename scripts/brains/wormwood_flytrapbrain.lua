require("behaviours/wander")
require("behaviours/chaseandattack")
require("behaviours/panic")
require("behaviours/attackwall")
require("behaviours/minperiod")
require("behaviours/faceentity")
require("behaviours/doaction")
require("behaviours/standstill")

local BrainCommon = require("brains/braincommon")

local SEE_FOOD_DIST = 30
local EAT_FOOD_NO_TAGS = {"INLIMBO", "irreplaceable", "outofreach", "smolder", "FX", "NOCLICK", "DECOR", "aquatic"}

local FOLLOW_DISTANCE_MIN = 0
local FOLLOW_DISTANCE_TARGET = 6
local FOLLOW_DISTANCE_MAX = 15

local function GetLeader(inst)
    return inst.components.follower and inst.components.follower:GetLeader() or nil
end

local function GetLeaderLocation(inst)
    local leader = GetLeader(inst)
    if leader == nil then
        return nil
    end

    return leader:GetPosition()
end

local function EatFoodAction(inst)
    -- print(string.format("stage & health & time: %d %d %d", inst.stage_plus, inst.components.health:GetPercent(), inst.components.timer:GetTimeLeft("finish_transformed_life")))
    if inst.sg:HasStateTag("busy") or (inst.stage_plus == 50 and inst.components.health:GetPercent() >= 0.85 
        and inst.components.timer:GetTimeLeft("finish_transformed_life") > 480 * 5) then
        return
    end

    local target = FindEntity(inst, SEE_FOOD_DIST, function(item)
        return inst.components.eater:CanEat(item)
            and item:IsOnValidGround()
            and item:GetTimeAlive() > TUNING.SPIDER_EAT_DELAY
    end, nil, EAT_FOOD_NO_TAGS)

    if target then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end
end

local FlytrapBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function FlytrapBrain:OnStart()
    local root = PriorityNode(
    {
        BrainCommon.PanicTrigger(self.inst),
        Follow(self.inst, GetLeader, FOLLOW_DISTANCE_MIN, FOLLOW_DISTANCE_TARGET, FOLLOW_DISTANCE_MAX),
        DoAction(self.inst, function() return EatFoodAction(self.inst) end ),
        ChaseAndAttack(self.inst, 10),
        StandStill(self.inst),
    }, 0.25)

    self.bt = BT(self.inst, root)
end

return FlytrapBrain
