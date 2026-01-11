-- globals
map_w_tiles = 128
map_h_tiles = 32
debug_map = true
debug_messages = {}

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

function _init()
    player_inst = player:new({})
    randomize_grass()
    -- spawn a flower at a random on-screen location
    spawn_entity(flower:new({ x = flr(rnd(1024)) + 4, y = flr(rnd(256)) + 4 }))
    spawn_entity(stump:new({ x = flr(rnd(1024)) + 4, y = flr(rnd(256)) + 4 }))
    spawn_entity(enemy:new({ x = flr(rnd(1024)) + 4, y = flr(rnd(256)) + 4 }))
    spawn_enemy('bird', { x = flr(rnd(1024)) + 4, y = flr(rnd(256)) + 4 })

    local map_w_px = map_w_tiles * 8
    local map_h_px = map_h_tiles * 8

    spawn_entity(base:new({ x = flr(map_w_px / 2), y = flr(map_h_px / 2) }))

    player_inst = player:new({})
    player_inst.x = flr(map_w_px / 2)
    player_inst.y = flr(map_h_px / 2)
    spawn_entity(player_inst)
end

function _update60()
    update_entities()
    update_attacks()
end

function _draw()
    cls()

    local map_w_px = map_w_tiles * 8
    local map_h_px = map_h_tiles * 8
    if not cam then cam = { x = 0, y = 0 } end
    local target_x = mid(0, player_inst.x - 64, max(0, map_w_px - 128))
    local target_y = mid(0, player_inst.y - 64, max(0, map_h_px - 128))
    cam.x += (target_x - cam.x) * 0.12
    cam.y += (target_y - cam.y) * 0.12
    camera(cam.x, cam.y)

    -- draw world under camera
    map()
    draw_attacks('behind')
    draw_entities()
    draw_attacks('front')

    -- reset camera for HUD
    camera()
    rectfill(2, 2, 34, 8, 0)
    rectfill(3, 3, 3 + flr(threat.value * 0.3), 7, 8)
    if debug_map then
        local t_x = mid(0, player_inst.x - 64, max(0, map_w_px - 128))
        local t_y = mid(0, player_inst.y - 64, max(0, map_h_px - 128))
        print("map:"..map_w_tiles.."x"..map_h_tiles, 70, 2, 7)
        print("map_px:"..map_w_px.."x"..map_h_px, 70, 10, 7)
        if player_inst then print("player:"..flr(player_inst.x)..","..flr(player_inst.y), 70, 18, 7) end
        print("target:"..flr(t_x)..","..flr(t_y), 70, 26, 7)
        if cam then print("cam:"..flr(cam.x)..","..flr(cam.y), 70, 34, 7) end
        -- draw queued debug messages (from update phase)
        if debug_messages and #debug_messages > 0 then
            for i=1,min(#debug_messages,6) do
                print(debug_messages[i], 2, 42 + (i-1) * 8, 7)
            end
        end
        debug_messages = {}
        -- list entities and positions for debugging
        if entities then
            for i=1,min(#entities,8) do
                local e = entities[i]
                local flags = ""
                if e == player_inst then flags = flags.."P" end
                if e == stump then flags = flags.."Sproto" end
                if e == entity then flags = flags.."Cproto" end
                if e == base then flags = flags.."B" end
                if e.solid then flags = flags.." solid" end
                local hb = (e.hitbox and e.hitbox[1]) or ((e.r and "circle") or "?")
                print((e.type or "ent")..":"..flr(e.x)..","..flr(e.y).." "..hb..flags, 2, 90 + (i-1) * 8, 7)
            end
        end
    end
end