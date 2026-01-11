-- globals
map_w_tiles = 128
map_h_tiles = 32
debug_map = true
scene = "outdoors" -- later set to "indoors"
debug_messages = {}
grass = {}

wall_ul = 12 wall_u = 13 wall_ur = 14
wall_l = 28 wall_r = 30
wall_dl = 44 wall_d = 45 wall_dr = 46
door_s = 61
floor_s = 29

wall_spr = 30 floor_spr = 29

door_x = 2 -- 0..4 (2 means centered)

day = 1

pending_outdoor_reset = false

inv_open = false
inv_hold = 0
inv_sel = 1 -- 1..3
loadout = { tool = 1, use = 0 } -- placeholder ids for now

inv_counts = inv_counts or {}

use_defs={"potion"} -- index 1 = potion (for now)

function inv_add(id,n)
 n=n or 1
 inv_counts[id]=(inv_counts[id] or 0)+n
 if id=="potion" and (loadout.use or 0)==0 then
  loadout.use=1
 end
end

function inv_add(id, n)
    n = n or 1
    inv_counts[id] = (inv_counts[id] or 0) + n
    -- auto-equip first potion into the consumable slot
    if id == "potion" then
        loadout = loadout or {}
        if not loadout.use then loadout.use = "potion" end
    end
    add(debug_messages, loadout.use)
end

function request_outdoor_reset()
    pending_outdoor_reset = true
end

function reset_outdoors()
    scene = "outdoors"
    entities = {}
    attacks = {}
    gen_grass()
    local mw, mh = map_w_tiles * 8, map_h_tiles * 8
    base_inst = base:new({ x = flr(mw / 2), y = flr(mh / 2) })
    player_inst = player:new({})
    player_inst.x = base_inst.x
    player_inst.y = base_inst.y + 8
    spawn_item("flower", { x = flr(rnd(1024)) + 4, y = flr(rnd(256)) + 4 })
    spawn_item("potion", { x = flr(rnd(1024)) + 4, y = flr(rnd(256)) + 4 })
    spawn_entity(base_inst)
    spawn_entity(player_inst)
    spawn_enemy('bird', { x = flr(rnd(mw)), y = flr(rnd(mh)) })
    spawn_enemy('blob', { x = flr(rnd(mw)), y = flr(rnd(mh)) })
end

function room_tile_spr(x, y)
    if y == 4 and x == door_x then return door_s end
    if x == 0 and y == 0 then return wall_ul end
    if x == 4 and y == 0 then return wall_ur end
    if x == 0 and y == 4 then return wall_dl end
    if x == 4 and y == 4 then return wall_dr end
    if y == 0 then return wall_u end
    if y == 4 then return wall_d end
    if x == 0 then return wall_l end
    if x == 4 then return wall_r end
    return floor_s
end

function draw_room5x5()
    local ox, oy = 64 - 20, 64 - 20
    for y = 0, 4 do
        for x = 0, 4 do
            local s = (x == 0 or x == 4 or y == 0 or y == 4) and wall_spr or floor_spr
            spr(room_tile_spr(x, y), ox + x * 8, oy + y * 8)
        end
    end
    return ox, oy
end

function spawn_player_in_room()
    local ox, oy = draw_room5x5()
    local tx = 1 + flr(rnd(3))
    -- 1..3
    local ty = 1 + flr(rnd(3))
    player_inst.x = ox + tx * 8 + 4
    player_inst.y = oy + ty * 8 + 4
end

indoor = { tx = 0, ty = 0, w = 7, h = 4, spawn_tx = 2, spawn_ty = 2 }

function indoor_draw_xy()
    local pxw, pxh = indoor.w * 8, indoor.h * 8
    return flr((128 - pxw) / 2), flr((128 - pxh) / 2)
end

function gen_grass()
    grass = {}
    for ty = 0, map_h_tiles - 1 do
        for tx = 0, map_w_tiles - 1 do
            if rnd() < 0.10 then
                add(grass, { x = tx * 8, y = ty * 8, s = 17 + flr(rnd(2)) })
            end
        end
    end
end

function grass_h(tx, ty)
    local n = bxor(tx, shl(ty, 8))
    n = bxor(n, shl(n, 13))
    n = bxor(n, shr(n, 17))
    n = bxor(n, shl(n, 5))
    return band(n + grass_seed * 17, 255)
end

function draw_grass_outdoors()
    local sx, sy = flr(cam.x / 8), flr(cam.y / 8)
    for ty = sy, sy + 16 do
        for tx = sx, sx + 16 do
            local n = tx * 4096 + ty * 17 + grass_seed
            n = bxor(n, shl(n, 5))
            n = bxor(n, shr(n, 3))
            n = bxor(n, shl(n, 7))
            local h = grass_h(tx, ty)
            if h < 26 then spr(17 + band(h, 1), tx * 8, ty * 8) end
        end
    end
end
threat = { value = 0, rise_rate = 0.01, last_alert = 0 }

function randomize_grass()
    for tx = 0, map_w_tiles - 1 do
        for ty = 0, map_h_tiles - 1 do
            if rnd() < 0.10 then
                mset(tx, ty, 17 + flr(rnd(2))) -- grass variants on ~10% of tiles
            end
        end
    end
end
-- increase over time (call each _update60)
function update_threat()
    threat.value = min(100, threat.value + threat.rise_rate)
    -- small periodic base damage when high
    if threat.value >= 80 and (time() - threat.last_alert) > 1 then
        base.hp = max(0, base.hp - 1)
        threat.last_alert = time()
        base.alert = true
    end
end

-- reduce threat (call when player does mitigating actions)
function reduce_threat(amount)
    threat.value = max(0, threat.value - (amount or 5))
end

function draw_quick_inv()
    if not inv_open then return end
    local x, y = 36, 110
    rectfill(x, y, x + 56, y + 10, 0)
    for i = 1, 3 do
        local c = (i == inv_sel) and 11 or 5
        rect(x + (i - 1) * 18 + 2, y + 2, x + (i - 1) * 18 + 16, y + 8, c)
    end
    print("inv", x + 2, y - 6, 7)
end

function _init()
    player_inst = player:new({})
    gen_grass()
    grass_seed = flr(rnd(32767))
    -- spawn a flower at a random on-screen location
    spawn_entity(stump:new({ x = flr(rnd(1024)) + 4, y = flr(rnd(256)) + 4 }))
    spawn_enemy('bird', { x = flr(rnd(1024)) + 4, y = flr(rnd(256)) + 4 })
    spawn_enemy('blob', { x = flr(rnd(1024)) + 4, y = flr(rnd(256)) + 4 })

    local map_w_px = map_w_tiles * 8
    local map_h_px = map_h_tiles * 8

    spawn_entity(base:new({ x = flr(map_w_px / 2), y = flr(map_h_px / 2) }))
    spawn_item("flower", { x = flr(rnd(1024)) + 4, y = flr(rnd(256)) + 4 })
    spawn_item("potion", { x = flr(rnd(1024)) + 4, y = flr(rnd(256)) + 4 })
    player_inst = player:new({})
    player_inst.x = flr(map_w_px / 2)
    player_inst.y = flr(map_h_px / 2)
    spawn_entity(player_inst)
end

function _update60()
    update_entities()
    update_attacks()
    if pending_outdoor_reset then
        pending_outdoor_reset = false
        reset_outdoors()
    end
end

function _draw()
    if scene == "indoors" then
        cls(0)
        camera(0, 0)
        draw_room5x5()
        camera()
    else
        cls(scene == "outdoors" and 11)
    end

    local map_w_px = map_w_tiles * 8
    local map_h_px = map_h_tiles * 8
    if not cam then cam = { x = 0, y = 0 } end
    if scene == "outdoors" then
        local target_x = mid(0, player_inst.x - 64, max(0, map_w_px - 128))
        local target_y = mid(0, player_inst.y - 64, max(0, map_h_px - 128))
        cam.x += (target_x - cam.x) * 0.12
        cam.y += (target_y - cam.y) * 0.12
        camera(cam.x, cam.y)
        for g in all(grass) do
            spr(g.s, g.x, g.y)
        end
    else
        camera(0, 0)
    end
    if scene == "outdoors" then
        for g in all(grass) do
            spr(g.s, g.x, g.y)
        end
    end

    -- draw world under camera
    draw_attacks('behind')
    draw_entities()
    draw_attacks('front')

    -- reset camera for HUD
    camera()
    rectfill(2, 2, 34, 8, 0)
    rectfill(3, 3, 3 + flr(threat.value * 0.3), 7, 8)
    draw_quick_inv()
    print(loadout.use)
    -- if debug_map then
    --     local t_x = mid(0, player_inst.x - 64, max(0, map_w_px - 128))
    --     local t_y = mid(0, player_inst.y - 64, max(0, map_h_px - 128))
    --     print("map:" .. map_w_tiles .. "x" .. map_h_tiles, 70, 2, 7)
    --     print("map_px:" .. map_w_px .. "x" .. map_h_px, 70, 10, 7)
    --     if player_inst then print("player:" .. flr(player_inst.x) .. "," .. flr(player_inst.y), 70, 18, 7) end
    --     print("target:" .. flr(t_x) .. "," .. flr(t_y), 70, 26, 7)
    --     if cam then print("cam:" .. flr(cam.x) .. "," .. flr(cam.y), 70, 34, 7) end
    --     -- draw queued debug messages (from update phase)
    --     if debug_messages and #debug_messages > 0 then
    --         for i = 1, min(#debug_messages, 6) do
    --             print(debug_messages[i], 2, 42 + (i - 1) * 8, 7)
    --         end
    --     end
    --     debug_messages = {}
    --     -- list entities and positions for debugging
    --     if entities then
    --         for i = 1, min(#entities, 8) do
    --             local e = entities[i]
    --             local flags = ""
    --             if e == player_inst then flags = flags .. "P" end
    --             if e == stump then flags = flags .. "Sproto" end
    --             if e == entity then flags = flags .. "Cproto" end
    --             if e == base then flags = flags .. "B" end
    --             if e.solid then flags = flags .. " solid" end
    --             local hb = (e.hitbox and e.hitbox[1]) or ((e.r and "circle") or "?")
    --             print((e.type or "ent") .. ":" .. flr(e.x) .. "," .. flr(e.y) .. " " .. hb .. flags, 2, 90 + (i - 1) * 8, 7)
    --         end
    --     end
    -- end
end