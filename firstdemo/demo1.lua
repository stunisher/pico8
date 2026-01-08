function demo1_init()
    x = 64
    y = 64
    spd = 1
    grid_on = false
    snap_on = false
end

function demo1_update()
    if was_pressed(4) then
        snap_on = not snap_on
    end

    if was_pressed(5) then
        grid_on = not grid_on
    end

    if btn(0) then x -= spd end -- left
    if btn(1) then x += spd end -- right
    if btn(2) then y -= spd end -- up
    if btn(3) then y += spd end -- down

    if btn(5) then
        if was_pressed(2) then spd += 0.1 end
        if was_pressed(3) then spd = max(0.1, spd - 0.1) end
    end
end

function demo1_draw()
    if grid_on then draw_grid() end
    print("demo: " .. demo_i .. " (grid & snap)", 1, 7, 7)
    print("x:" .. x .. "  y:" .. y, 1, 13, 7)
    print("tx:" .. flr(x / 8) .. "  ty:" .. flr(y / 8), 1, 19, 7)
    print("speed:" .. tostring(fmt(spd, 2)))
    print(grid_on)

    draw_crosshair()
end

function draw_crosshair()
    local draw_x, draw_y = x, y
    if snap_on then
        draw_x = flr(x / 8) * 8
        draw_y = flr(y / 8) * 8
    end
    circfill(draw_x, draw_y, 3, 8)
end

function draw_grid()
    for i = 0, 15 do
        line(i * 8, 0, i * 8, 127, 1)
        line(0, i * 8, 127, i * 8, 1)
    end
end