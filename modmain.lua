GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})
env.RECIPETABS = GLOBAL.RECIPETABS 
env.TECH = GLOBAL.TECH


Assets = {
    Asset("IMAGE", "images/inventoryimages/moon_tree_blossom_charged.tex"),
    Asset("ATLAS", "images/inventoryimages/moon_tree_blossom_charged.xml"),
    Asset("IMAGE", "images/inventoryimages/wormwood_carrat.tex"),
    Asset("ATLAS", "images/inventoryimages/wormwood_carrat.xml"),
    Asset("IMAGE", "images/inventoryimages/wormwood_fruitdragon.tex"),
    Asset("ATLAS", "images/inventoryimages/wormwood_fruitdragon.xml"),
    Asset("IMAGE", "images/inventoryimages/wormwood_piko.tex"),
    Asset("ATLAS", "images/inventoryimages/wormwood_piko.xml"),
    Asset("IMAGE", "images/inventoryimages/wormwood_piko_orange.tex"),
    Asset("ATLAS", "images/inventoryimages/wormwood_piko_orange.xml"),
    Asset("IMAGE", "images/inventoryimages/wormwood_grassgator.tex"),
    Asset("ATLAS", "images/inventoryimages/wormwood_grassgator.xml"),
    Asset("IMAGE", "images/inventoryimages/wormwood_flytrap.tex"),
    Asset("ATLAS", "images/inventoryimages/wormwood_flytrap.xml"),
    Asset("IMAGE", "images/inventoryimages/wormwood_mandrakeman.tex"),
    Asset("ATLAS", "images/inventoryimages/wormwood_mandrakeman.xml"),
    Asset("IMAGE", "images/inventoryimages/wormwood_mushroombomb.tex"),
    Asset("ATLAS", "images/inventoryimages/wormwood_mushroombomb.xml"),
    Asset("IMAGE", "images/inventoryimages/wormwood_mushroombomb_gas.tex"),
    Asset("ATLAS", "images/inventoryimages/wormwood_mushroombomb_gas.xml"),
    Asset("IMAGE", "images/inventoryimages/ivystaff.tex"),
    Asset("ATLAS", "images/inventoryimages/ivystaff.xml"),

    
    Asset("IMAGE", "images/skilltree_icons/wormwood_seed.tex"),
    Asset("ATLAS", "images/skilltree_icons/wormwood_seed.xml"),
    Asset("IMAGE", "images/skilltree_icons/wormwood_background.tex"),
    Asset("ATLAS", "images/skilltree_icons/wormwood_background.xml"),
    Asset("IMAGE", "images/skilltree_icons/wormwood_pets_piko.tex"),
    Asset("ATLAS", "images/skilltree_icons/wormwood_pets_piko.xml"),
    Asset("IMAGE", "images/skilltree_icons/wormwood_pets_grassgator.tex"),
    Asset("ATLAS", "images/skilltree_icons/wormwood_pets_grassgator.xml"),
    Asset("IMAGE", "images/skilltree_icons/wormwood_pets_flytrap.tex"),
    Asset("ATLAS", "images/skilltree_icons/wormwood_pets_flytrap.xml"),
    Asset("IMAGE", "images/skilltree_icons/wormwood_mushroom_mushroombomb.tex"),
    Asset("ATLAS", "images/skilltree_icons/wormwood_mushroom_mushroombomb.xml"),
    Asset("IMAGE", "images/skilltree_icons/wormwood_mushroom_shroomcake.tex"),
    Asset("ATLAS", "images/skilltree_icons/wormwood_mushroom_shroomcake.xml"),
    Asset("IMAGE", "images/skilltree_icons/wormwood_mushroom_mushroomhat.tex"),
    Asset("ATLAS", "images/skilltree_icons/wormwood_mushroom_mushroomhat.xml"),
    Asset("IMAGE", "images/skilltree_icons/wormwood_thorn_cactus.tex"),
    Asset("ATLAS", "images/skilltree_icons/wormwood_thorn_cactus.xml"),
    Asset("IMAGE", "images/skilltree_icons/wormwood_thorn_deciduoustree.tex"),
    Asset("ATLAS", "images/skilltree_icons/wormwood_thorn_deciduoustree.xml"),
    Asset("IMAGE", "images/skilltree_icons/wormwood_thorn_ivystaff.tex"),
    Asset("ATLAS", "images/skilltree_icons/wormwood_thorn_ivystaff.xml"),
    Asset("IMAGE", "images/skilltree_icons/wormwood_blooming_lunartree.tex"),
    Asset("ATLAS", "images/skilltree_icons/wormwood_blooming_lunartree.xml"),
    Asset("IMAGE", "images/skilltree_icons/wormwood_blooming_opalstaff.tex"),
    Asset("ATLAS", "images/skilltree_icons/wormwood_blooming_opalstaff.xml"),

    Asset("SOUND", "sound/DLC003_sfx.fsb"),
    Asset("SOUNDPACKAGE", "sound/dontstarve_DLC003.fev"),
}

PrefabFiles = {
    "wormwood_mushroombomb",
    "wormwood_mushroombomb_gas",
    "moontree_plant_fx",
    "moon_tree_blossom_charged",
    "wormwood_meteor_terraformer",
    "wormwood_gestalt_guard",
    "wormwood_gestalt_head",
    "wormwood_lunar_grazer",
    "wormwood_piko",
    "wormwood_mutantproxy_piko",
    "wormwood_grassgator",
    "wormwood_mutantproxy_grassgator",
    "wormwood_flytrap",
    "wormwood_mutantproxy_flytrap",
    "wormwood_mandrakeman",
    "wormwood_mutantproxy_mandrakeman",
    "ivystaff",
    "bramble",
    "wormwood_lunarthrall_plant",
}

local lan = (GLOBAL.LanguageTranslator.defaultlang == "zh") and "zh" or "en"
if lan == "zh" then
    modimport("languages/chs")
else
    modimport("languages/en")
end

modimport("scripts/skilltree") 
modimport("scripts/skill_pets")
modimport("scripts/skill_mushroom")
modimport("scripts/skill_thorn")
modimport("scripts/skill_blooming")

-- modimport("scripts/mushroom_farm_reset") 
modimport("scripts/recipe") 


-- 草鳄鱼添加容器功能代码来自宠物箱子 mod：https://steamcommunity.com/sharedfiles/filedetails/?id=2878207237  我的救星 QAQ
local _G = GLOBAL
local Vector3 = _G.Vector3

local containers = require "containers"
local params = {}

local containers_widgetsetup_base = containers.widgetsetup
function containers.widgetsetup(container, prefab, data, ...)
    local t = params[prefab or container.inst.prefab]
    if t ~= nil then
        for k, v in pairs(t) do
            container[k] = v
        end
        container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
    else
        containers_widgetsetup_base(container, prefab, data, ...)
    end
end


params.pet_container = 
{
    widget =
    {
        slotpos = {
            -- 第一行
            Vector3(-75, 64 + 8, 0),  -- 左上
            Vector3(0, 64 + 8, 0),    -- 中上
            Vector3(75, 64 + 8, 0),   -- 右上
            
            -- 第二行
            Vector3(-75, 0, 0),       -- 左中
            Vector3(0, 0, 0),         -- 正中
            Vector3(75, 0, 0),        -- 右中
            
            -- 第三行
            Vector3(-75, -64 - 8, 0), -- 左下
            Vector3(0, -64 - 8, 0),   -- 中下
            Vector3(75, -64 - 8, 0)   -- 右下
        },
        animbank = "ui_chest_3x3",
        animbuild = "ui_chest_3x3",
        pos = Vector3(0, 150, 0),
    },
    type = "critter",
    itemtestfn = function(inst, item, slot) -- 容器里可以装的物品的条件
        return not item:HasTag("_container") and not item:HasTag("irreplaceable")
    end
}

for k, v in pairs(params) do
    containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
end

AddPrefabPostInit("wormwood_grassgator", function(inst)
    if not _G.TheWorld.ismastersim then
        inst.OnEntityReplicated = function(inst) 
			inst.replica.container:WidgetSetup("pet_container") 
		end
    elseif not inst.components.container then
        inst:AddComponent("container")
        inst.components.container:WidgetSetup("pet_container")
        inst.components.container.canbeopened = true
    end
end)