require("behaviours/wander")
require("behaviours/runaway")
require("behaviours/doaction")
require("behaviours/panic")
require("behaviours/chaseandattack")

local BrainCommon = require("brains/braincommon")

-- 常量定义
local STOP_RUN_DIST = 10
local SEE_PLAYER_DIST = 5
local AVOID_PLAYER_DIST = 3
local AVOID_PLAYER_STOP = 6
local SEE_BAIT_DIST = 20
local MAX_WANDER_DIST = 8
local SEE_STOLEN_ITEM_DIST = 15
local MAX_CHASE_TIME = 8
local SEE_BAIT_MAXDIST = 20
local MAX_FOOD_STORAGE = 5 -- 松鼠最多私藏的食物数量

local FOLLOW_DISTANCE_MIN = 0
local FOLLOW_DISTANCE_TARGET = 8
local FOLLOW_DISTANCE_MAX = 15

local function GetLeader(inst)
    return inst.components.follower and inst.components.follower:GetLeader() or nil
end

local function GetLeaderLocation(inst)
    local leader = GetLeader(inst)
    return leader and leader:GetPosition() or nil
end

-- 检查物品是否可食用
local function IsItemEdible(inst, item)
    if item.components.edible then
        if item.components.edible.foodtype == FOODTYPE.VEGGIE then 
            return true
        end
    else
        return false
    end
end

local function LeaderFull(inst)
    local leader = GetLeader(inst)
    if not leader or not leader.components.inventory then
        return false
    end
    
    local inventoryfull = leader.components.inventory:NumItems() >= leader.components.inventory.maxslots
    local backpackfull = false

    local backpack = leader.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    if backpack and backpack.components.container then
        backpackfull = backpack.components.container:NumItems() >= backpack.components.container.numslots
    end

    -- 检查领导者的物品栏是否已满
    return inventoryfull and backpackfull
end

-- 给予物品动作（按顺序给予非食物类物品）
local function GiveToPlayerAction(inst)
    local leader = GetLeader(inst)
    if LeaderFull(inst) then
        inst.pickup_blocked = false
        return nil
    end

    -- 获取松鼠的物品栏
    local inventory = inst.components.inventory
    if not inventory then
        return nil
    end

    -- 遍历所有物品栏位
    for i = 1, inventory.maxslots do
        local item = inventory:GetItemInSlot(i)
        if item then
            if not IsItemEdible(inst, item) then
                return BufferedAction(inst, leader, ACTIONS.GIVEALLTOPLAYER, item)
            end
        end
    end

    inst.pickup_blocked = false
    return nil
end

local function PlayerHasSameItem(leader, target)
    if not leader or not leader.components.inventory or not target then
        return false
    end
    
    local target_prefab = target.prefab
    
    -- 检查玩家物品栏中是否有相同prefab的物品
    for k, item in pairs(leader.components.inventory.itemslots) do
        if item and item.prefab == target_prefab then
            return true
        end
    end
    local backpack = leader.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    if backpack and backpack.components.container then
        for i = 1, backpack.components.container:GetNumSlots() do
            local item = backpack.components.container:GetItemInSlot(i)
            if item and item.prefab == target_prefab then
                return true
            end
        end
    end
    return false
end
-- 拾取动作
local PICKUP_MUST_TAGS = {"_inventoryitem"}
local NO_PICKUP_TAGS = {"INLIMBO", "catchable", "fire", "irreplaceable", "heavy", "outofreach", "spider", "piko", "trap", "_container", "smolder"}

local function PickupAction(inst)
    if inst.sg:HasStateTag("trapped") then
        return
    end

    if inst.components.inventory:NumItems() >= inst.components.inventory.maxslots or inst.pickup_blocked then
        inst.pickup_blocked = true
        return GiveToPlayerAction(inst)
    else
        -- 寻找可拾取的物品
        local target = FindEntity(inst, SEE_STOLEN_ITEM_DIST, function(item)
            return IsItemEdible(inst, item) or 
                item.components.inventoryitem and
                not item.components.inventoryitem.owner and
                item.components.inventoryitem.canbepickedup and
                item:IsOnValidGround() and
                PlayerHasSameItem(inst.components.follower.leader, item) and
                not item.components.equippable
        end, PICKUP_MUST_TAGS, NO_PICKUP_TAGS)

        -- 如果找到可拾取的物品且松鼠的物品栏未满
        if target then
            return BufferedAction(inst, target, ACTIONS.PICKUP)
        end
    end
end

-- 吃东西动作
-- local function EatFoodAction(inst)
--     if not inst.components.inventory then
--         return
--     end
    
--     -- 从物品栏中找可吃的食物
--     for k, item in pairs(inst.components.inventory.itemslots) do
--         if IsItemEdible(inst, item) then
--             return BufferedAction(inst, item, ACTIONS.EAT)
--         end
--     end
-- end

local function ShouldRunFromScary(other, inst)
    local isplayer = other:HasTag("player")
    if isplayer and GetLeader(inst) == other then
        return false
    end

    local isplayerpet = isplayer and other.components.petleash and other.components.petleash:IsPet(inst)
    return (isplayer or isplayerpet) and TheNet:GetPVPEnabled()
end


-- local function PickUpFilter(inst, target, leader)
--     return PlayerHasSameItem(leader, target)
-- end

local PikoBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local NORMAL_RUNAWAY_DATA = {tags = {"scarytoprey"}, fn = ShouldRunFromScary}

function PikoBrain:OnStart()

    -- local leader = GetLeader(self.inst)

    -- local ignorethese = nil
    -- if leader ~= nil then
    --     ignorethese = leader._brain_pickup_ignorethese or {}
    --     leader._brain_pickup_ignorethese = ignorethese
    -- end

    -- local pickupparams = {
    --     range = SEE_BAIT_MAXDIST,
    --     custom_pickup_filter = PickUpFilter,
    --     ignorethese = ignorethese,
    -- }
    
    local root = PriorityNode(
    {
        BrainCommon.PanicTrigger(self.inst),
        RunAway(self.inst, NORMAL_RUNAWAY_DATA, AVOID_PLAYER_DIST, AVOID_PLAYER_STOP),
        Follow(self.inst, GetLeader, FOLLOW_DISTANCE_MIN, FOLLOW_DISTANCE_TARGET, FOLLOW_DISTANCE_MAX),
        
        -- 优先吃自己保留的食物
        -- DoAction(self.inst, EatFoodAction, "eat food", true),
        
        -- 拾取物品
        DoAction(self.inst, PickupAction, "pick up item", true),
        
        -- 给予玩家非食物物品
        DoAction(self.inst, GiveToPlayerAction, "give to player", true),
        
        
        -- 辅助玩家拾取物品
        -- WhileNode(function() return GetLeader(self.inst) ~= nil end, "Has Leader",
        --     BrainCommon.NodeAssistLeaderPickUps(self, pickupparams)
        -- ),
        
        Wander(self.inst, GetLeaderLocation, MAX_WANDER_DIST),
    }, 0.25)

    self.bt = BT(self.inst, root)
end

return PikoBrain