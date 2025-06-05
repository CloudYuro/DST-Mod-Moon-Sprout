require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/runaway"

local BrainCommon = require("brains/braincommon")

local MAX_CHASE_TIME = 6
local WANDER_DIST = TUNING.SHADE_CANOPY_RANGE -2

local RUN_AWAY_DIST = 8
local STOP_RUN_AWAY_DIST = 14
local START_FACE_DIST = 5
local KEEP_FACE_DIST = 6
local MAX_WANDER_DIST = 15


local FOLLOW_DISTANCE_MIN = 0
local FOLLOW_DISTANCE_TARGET = 8
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

local function GetFaceTargetFn(inst)
    if not BrainCommon.ShouldSeekSalt(inst) then
        local target = FindClosestPlayerToInst(inst, START_FACE_DIST, true)
        if not inst.components.timer:TimerExists("facetarget") then
            inst.components.timer:StartTimer("facetarget",3)
        end
        return target ~= nil and not target:HasTag("notarget") and target or nil
    end
end

local function KeepFaceTargetFn(inst, target)
    return not BrainCommon.ShouldSeekSalt(inst)
        and not target:HasTag("notarget")
        and inst.components.timer:TimerExists("facetarget")
        and inst:IsNear(target, KEEP_FACE_DIST)
end

-- local function ShouldRunAway(guy)
--     return guy:HasTag("hostile") 
-- end

local GrassgatorBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function isonland(inst)
    return TheWorld.Map:IsVisualGroundAtPoint(inst.Transform:GetWorldPosition())
end

local function getwanderloc(inst)
    return (not isonland(inst) and inst.components.knownlocations:GetLocation("home"))
        or nil
end

function GrassgatorBrain:OnStart()
    local function ShouldRunAway(guy)
        if self.inst.shouldfight then
            return false
        end
        return guy:HasTag("hostile") 
    end

    local root = PriorityNode(
    {
        WhileNode(function() return not self.inst.sg:HasStateTag("diving") end, "Not Diving",
            PriorityNode(
            {
				BrainCommon.PanicTrigger(self.inst),
                Follow(self.inst, GetLeader, FOLLOW_DISTANCE_MIN, FOLLOW_DISTANCE_TARGET, FOLLOW_DISTANCE_MAX),
                WhileNode(function() return self.inst.shouldfight end, "Can Fight", ChaseAndAttack(self.inst, MAX_CHASE_TIME)),
                SequenceNode{
                    RunAway(self.inst, ShouldRunAway, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST),
                    FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn, 0.5)
                },
                FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
                Wander(self.inst, GetLeaderLocation, MAX_WANDER_DIST),
            }, .25)),
    }, .25)

    self.bt = BT(self.inst, root)
end

return GrassgatorBrain
