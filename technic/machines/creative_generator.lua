-- technic/technic/register/creative_generator.lua
-- Creative-only node that feeds power into the grid for free
-- Copyright (c) 2026  Technic Developers
-- SPDX-License-Identifier: LGPL-2.1-or-later

local S = technic.getter
local digilines_exists = core.get_modpath("digilines") and true or false

local function set_creative_generator_formspec(meta)
    local formspec = "size[5,2.25]" ..
        "field[0.3,0.5;2,1;power;" .. S("Output Power") .. ";${power}]"
    if digilines_exists then
        formspec = formspec ..
            "field[2.3,0.5;3,1;channel;" .. S("Digiline Channel") .. ";${channel}]"
    end
    -- The names for these toggle buttons are explicit about which
    -- state they'll switch to, so that multiple presses (arising
    -- from the ambiguity between lag and a missed press) only make
    -- the single change that the user expects.
    if meta:get_int("mesecon_mode") == 0 then
        formspec = formspec .. "button[0,1;5,1;mesecon_mode_1;" .. S("Ignoring Mesecon Signal") .. "]"
    else
        formspec = formspec .. "button[0,1;5,1;mesecon_mode_0;" .. S("Controlled by Mesecon Signal") .. "]"
    end
    if meta:get_int("enabled") == 0 then
        formspec = formspec .. "button[0,1.75;5,1;enable;" .. S("@1 Disabled", S("Creative Generator")) .. "]"
    else
        formspec = formspec .. "button[0,1.75;5,1;disable;" .. S("@1 Enabled", S("Creative Generator")) .. "]"
    end
    meta:set_string("formspec", formspec)
end

local def = {
    description = S("Creative Generator"),
    tiles = {
        "technic_hv_generator_top.png",
        "technic_machine_bottom.png^technic_cable_connection_overlay.png",
        "technic_hv_generator_side.png^technic_creative_generator_overlay.png",
        "technic_hv_generator_side.png^technic_creative_generator_overlay.png",
        "technic_hv_generator_side.png^technic_creative_generator_overlay.png",
        "technic_hv_generator_side.png^technic_creative_generator_overlay.png"
    },
    groups = {
        snappy = 2,
        choppy = 2,
        oddly_breakable_by_hand = 2,
        technic_machine = 1,
        technic_all_tiers = 1,
        axey = 2,
        handy = 1,
    },
    connect_sides = { "bottom" },
    sounds = technic.sounds.node_sound_wood_defaults(),
    drop = "",
}

def.on_construct = function(pos)
    local meta = core.get_meta(pos)
    meta:set_string("infotext", S("Creative Generator"))
    meta:set_int("power", 100000)
    meta:set_int("enabled", 1)
    meta:set_int("mesecon_mode", 0)
    meta:set_int("mesecon_effect", 0)
    set_creative_generator_formspec(meta)
end

def.on_receive_fields = function(pos, formname, fields, sender)
    if not sender or core.is_protected(pos, sender:get_player_name()) then
        return
    end
    local meta = core.get_meta(pos)
    local power = nil
    if fields.power then
        power = tonumber(fields.power) or 0
        power = math.max(power, 0)
        power = math.min(power, 2147483647)
        power = math.floor(power)
        if power == meta:get_int("power") then power = nil end
    end
    if power then meta:set_int("power", power) end
    if fields.channel then meta:set_string("channel", fields.channel) end
    if fields.enable then meta:set_int("enabled", 1) end
    if fields.disable then meta:set_int("enabled", 0) end
    if fields.mesecon_mode_0 then meta:set_int("mesecon_mode", 0) end
    if fields.mesecon_mode_1 then meta:set_int("mesecon_mode", 1) end
    set_creative_generator_formspec(meta)
end

if core.get_modpath("mesecons") then
    def.mesecons = {
        effector = {
            action_on = function(pos, node)
                core.get_meta(pos):set_int("mesecon_effect", 1)
            end,
            action_off = function(pos, node)
                core.get_meta(pos):set_int("mesecon_effect", 0)
            end
        }
    }
end

if digilines_exists then
    def.digilines = {
        receptor = {
            rules = technic.digilines.rules,
            action = function() end
        },
        effector = {
            rules = technic.digilines.rules,
            action = function(pos, node, channel, msg)
                if type(msg) ~= "string" then
                    return
                end
                local meta = core.get_meta(pos)
                if channel ~= meta:get_string("channel") then
                    return
                end
                msg = msg:lower()
                if msg == "get" then
                    digilines.receptor_send(pos, technic.digilines.rules, channel, {
                        enabled      = meta:get_int("enabled"),
                        power        = meta:get_int("power"),
                        mesecon_mode = meta:get_int("mesecon_mode")
                    })
                    return
                elseif msg == "off" then
                    meta:set_int("enabled", 0)
                elseif msg == "on" then
                    meta:set_int("enabled", 1)
                elseif msg == "toggle" then
                    local onn = meta:get_int("enabled")
                    onn = 1 - onn -- Mirror onn with pivot 0.5, so switch between 1 and 0.
                    meta:set_int("enabled", onn)
                elseif msg:sub(1, 5) == "power" then
                    local power = tonumber(msg:sub(7))
                    if not power then
                        return
                    end
                    power = math.max(power, 0)
                    power = math.min(power, 2147483647)
                    power = math.floor(power)
                    meta:set_int("power", power)
                elseif msg:sub(1, 12) == "mesecon_mode" then
                    meta:set_int("mesecon_mode", tonumber(msg:sub(14)))
                else
                    return
                end
                set_creative_generator_formspec(meta)
            end
        },
    }
end

def.technic_run = function(pos, node, run_stage)
    -- run only in producer stage.
    if run_stage == technic.receiver then
        return
    end

    -- Machine information
    local machine_name = S("Creative Generator")
    local meta         = core.get_meta(pos)
    local enabled      = meta:get_int("enabled") == 1 and
        (meta:get_int("mesecon_mode") == 0 or meta:get_int("mesecon_effect") ~= 0)

    local demand       = enabled and meta:get_int("power") or 0

    local pos_down     = vector.offset(pos, 0, -1, 0)
    local name_down    = core.get_node(pos_down).name

    local to           = technic.get_cable_tier(name_down)

    if to then
        meta:set_int(to .. "_EU_demand", 0)
        meta:set_int(to .. "_EU_supply", demand)
        meta:set_string("infotext", S("@1 (@2 @3)", machine_name,
            technic.EU_string(demand), to))
    else
        meta:set_string("infotext", S("@1 Has Bad Cabling", machine_name))
        if to then
            meta:set_int(to .. "_EU_supply", 0)
        end
        return
    end
end
def.technic_on_disable = def.technic_run

core.register_node("technic:creative_generator", def)

for tier, machines in pairs(technic.machines) do
    technic.register_machine(tier, "technic:creative_generator", technic.producer)
end
