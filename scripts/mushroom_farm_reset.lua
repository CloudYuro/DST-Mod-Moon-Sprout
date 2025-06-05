local levels =
{
    { amount=6, grow="mushroom_4", idle="mushroom_4_idle", hit="hit_mushroom_4" },  -- this can only be reached by starting with spores
    { amount=4, grow="mushroom_3", idle="mushroom_3_idle", hit="hit_mushroom_3" },  -- max for starting with mushrooms
    { amount=2, grow="mushroom_2", idle="mushroom_2_idle", hit="hit_mushroom_2" },
    { amount=1, grow="mushroom_1", idle="mushroom_1_idle", hit="hit_mushroom_1" },
    { amount=0, idle="idle", hit="hit_idle" },
}

local spore_to_cap =
{
    spore_tall = "blue_cap",
    spore_medium = "red_cap",
    spore_small = "green_cap",
}

local FULLY_REPAIRED_WORKLEFT = 3

local function DoMushroomOverrideSymbol(inst, product)
   inst.AnimState:OverrideSymbol("swap_mushroom", "mushroom_farm_"..(string.split(product, "_")[1]).."_build", "swap_mushroom")
end

local function StartGrowing(inst, giver, product)
    if inst.components.harvestable ~= nil then
        ---- 修改最大数量
        local is_spore = product:HasTag("spore")
        local max_produce = levels[2].amount        
        local productname = (is_spore and spore_to_cap[product.prefab]) or product.prefab
        local grow_time_percent = 1.0
        
        if giver:HasTag("wormwood_mushroom_planter") or is_spore then
            grow_time_percent = TUNING.WORMWOOD_MUSHROOMPLANTER_RATEBONUS_2
        end

        if giver:HasTag("wormwood_mushroom_rgb_cap_eating") then
            max_produce = levels[1].amount
        end

        local grow_time = grow_time_percent * TUNING.MUSHROOMFARM_FULL_GROW_TIME

        DoMushroomOverrideSymbol(inst, productname)

        inst.components.harvestable:SetProduct(productname, max_produce)
        inst.components.harvestable:SetGrowTime(grow_time / max_produce)
        inst.components.harvestable:Grow()

        TheWorld:PushEvent("itemplanted", { doer = giver, pos = inst:GetPosition() }) --this event is pushed in other places too
    end
end

local function setlevel(inst, level, dotransition) --引用原函数
    if not inst:HasTag("burnt") then
        if inst.anims == nil then
            inst.anims = {}
        end
        if inst.anims.idle == level.idle then
            dotransition = false
        end

        inst.anims.idle = level.idle
        inst.anims.hit = level.hit

        if inst.remainingharvests == 0 then
            inst.anims.idle = "expired"
            inst.components.trader:Enable()
            inst.components.harvestable:SetGrowTime(nil)
            inst.components.workable:SetWorkLeft(1)
        elseif TheWorld.state.issnowcovered then
            inst.components.trader:Disable()
        elseif inst.components.harvestable:CanBeHarvested() then
            inst.components.trader:Disable()
        else
            inst.components.trader:Enable()
            inst.components.harvestable:SetGrowTime(nil)
        end

        if dotransition then
            inst.AnimState:PlayAnimation(level.grow)
            inst.AnimState:PushAnimation(inst.anims.idle, false)
            inst.SoundEmitter:PlaySound(level ~= levels[1] and "dontstarve/common/together/mushroomfarm/grow" or "dontstarve/common/together/mushroomfarm/spore_grow")
        else
            inst.AnimState:PlayAnimation(inst.anims.idle)
        end

    end
end

local function updatelevel(inst, dotransition) --引用原函数
    if not inst:HasTag("burnt") then
        if TheWorld.state.issnowcovered then
            if inst.components.harvestable:CanBeHarvested() then
                for i= 1,inst.components.harvestable.produce do
                    inst.components.lootdropper:SpawnLootPrefab("spoiled_food")
                end

                inst.components.harvestable.produce = 0
                inst.components.harvestable:StopGrowing()
                inst.remainingharvests = inst.remainingharvests - 1
            end
        end

        for k, v in pairs(levels) do
            if inst.components.harvestable.produce >= v.amount then
                setlevel(inst, v, dotransition)
                break
            end
        end
    end
end

local function onacceptitem(inst, giver, item)
    if inst.remainingharvests == 0 then
        inst.remainingharvests = TUNING.MUSHROOMFARM_MAX_HARVESTS
        inst.components.workable:SetWorkLeft(FULLY_REPAIRED_WORKLEFT)
        updatelevel(inst)
    else
        StartGrowing(inst, giver, item)
    end
end

AddPrefabPostInit("mushroom_farm", function (inst)
    if inst and inst.components and inst.components.trader then
        inst.components.trader.onaccept = onacceptitem
    end
end)
