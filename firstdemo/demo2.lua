function demo2_init()
    px = 64
    -- x position
    py = 40
    -- y position
    vx = 0
    vy = 0
    ground_y = 110
    params = {
        { name = "g", val = 0.18, step = 0.01, min = -1, max = 2 },
        { name = "jump_impulse", val = -3.6, step = 0.1, min = -10, max = 0 },
        { name = "term_vy", val = 3.6, step = 0.1, min = 0.1, max = 20 },
        { name = "spd", val = 1.5, step = 0.1, min = 0.1, max = 8 }
    }
    param_i = 1
    -- which parameter is active
end

function demo2_update()
    if not btn(4) then
        if btn(0) then px -= params[4].val end
        if btn(1) then px += params[4].val end
    end

    if btn(4) then
        -- cycle active param with left/right
        if was_pressed(0) then
            param_i = param_i - 1
            if param_i < 1 then param_i = #params end
        elseif was_pressed(1) then
            param_i = param_i + 1
            if param_i > #params then param_i = 1 end
        end

        -- edit active param with up/down
        if was_pressed(2) then
            params[param_i].val = min(params[param_i].max, params[param_i].val + params[param_i].step)
        elseif was_pressed(3) then
            params[param_i].val = max(params[param_i].min, params[param_i].val - params[param_i].step)
        end

        -- while in param mode we usually don't want normal movement to happen,
        -- so early-return from physics update (optional)
        return
    end

    if was_pressed(5) and py >= ground_y then
        vy = params[2].val
    end

    -- gravity + integrate
    vy += params[1].val
    if vy > params[3].val then vy = params[3].val end
    py += vy

    -- ground collision (simple)
    if py > ground_y then
        py = ground_y
        vy = 0
    end

    -- clamp px on screen
    if px < 0 then px = 0 end
    if px > 127 then px = 127 end
end

function demo2_draw()
    -- ground
    rectfill(0, ground_y + 4, 127, 127, 2)
    -- player
    circfill(px, py, 4, 8)
    -- velocity meter (vertical bar)
    local bar_x = 110
    local bar_h = 40
    local vy_norm = (vy / params[3].val)
    -- -1..1 roughly
    local fill_h = mid(0, flr((vy_norm / 1.5) * bar_h), bar_h)
    rectfill(bar_x, 20, bar_x + 6, 20 + bar_h, 1)
    rectfill(bar_x + 1, 20 + bar_h - fill_h, bar_x + 5, 20 + bar_h, 8)

    -- HUD
    print("px:" .. fmt(px, 2) .. " py:" .. fmt(py, 2), 1, 13, 7)
    print("vy:" .. fmt(vy, 3) .. " g:" .. fmt(params[1].val, 3) .. " jump:" .. fmt(params[2].val, 2), 1, 19, 7)
    print("press X to jump", 1, 25, 6)
    print("🅾️+⬅️/➡️select🅾️+⬆️/⬇️ edit", 1, 31, 6)
    print("param: " .. params[param_i].name .. "=" .. fmt(params[param_i].val, 3), 1, 37, 7)
end

function fmt(n, d)
    local p = 10 ^ (d or 2)
    return (flr(n * p + 0.5) / p)
end