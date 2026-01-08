function demo2_init()
    px = 64
    -- x position
    py = 40
    -- y position
    vx = 0
    vy = 0
    g = 0.18
    -- gravity
    jump_impulse = -3.6
    term_vy = 3.6
    ground_y = 110
end

function demo2_update()
    if btn(0) then px -= spd end
    if btn(1) then px += spd end

    if was_pressed(5) and py >= ground_y then
        vy = jump_impulse
    end

    -- gravity + integrate
    vy += g
    if vy > term_vy then vy = term_vy end
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
    local vy_norm = (vy / term_vy)
    -- -1..1 roughly
    local fill_h = mid(0, flr((vy_norm / 1.5) * bar_h), bar_h)
    rectfill(bar_x, 20, bar_x + 6, 20 + bar_h, 1)
    rectfill(bar_x + 1, 20 + bar_h - fill_h, bar_x + 5, 20 + bar_h, 8)

    -- HUD
    print("demo: " .. demo_i .. " (jumping)", 1, 7, 7)
    print("px:" .. fmt(px, 2) .. " py:" .. fmt(py, 2), 1, 13, 7)
    print("vy:" .. fmt(vy, 3) .. " g:" .. fmt(g, 3) .. " jump:" .. fmt(jump_impulse, 2), 1, 19, 7)
    print("press X to jump", 1, 25, 6)
end

function fmt(n, d)
    local p = 10 ^ (d or 2)
    return (flr(n * p + 0.5) / p)
end