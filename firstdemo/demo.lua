function _init()
    demos = {
        { name = "grid & snap", init = demo1_init, update = demo1_update, draw = demo1_draw },
        { name = "jumping",     init = demo2_init, update = demo2_update, draw = demo2_draw },
        { name = "orbiting",    init = demo3_init, update = demo3_update, draw = demo3_draw }
    }
    demo_count = #demos
    demo_i = 1
    in_demo = false
    prev_btn = { false, false, false, false, false, false }
    demos[demo_i].init()
end

function _update60()
    if (btn(4) and was_pressed(5)) or (btn(5) and was_pressed(4)) then
        if (not in_demo) and demos[demo_i].init then
            demos[demo_i].init()
        end
        in_demo = not in_demo
    end

    if not in_demo then
        if was_pressed(0) then
            demo_i -= 1
            if demo_i < 1 then demo_i = demo_count end
            demos[demo_i].init()
        elseif was_pressed(1) then
            demo_i += 1
            if demo_i > demo_count then demo_i = 1 end
            demos[demo_i].init()
        end
    elseif in_demo and demos[demo_i].update then
        local d = demos[demo_i]
        if d and d.update then d.update() end
    end

    for i = 0, 5 do
        prev_btn[i + 1] = btn(i)
    end
end

function _draw()
    cls()
    local d = demos[demo_i]
    if d and d.draw then d.draw() end
    if in_demo then
        print("🅾️+❎exit demo", 1, 1, 6)
    else
        print("🅾️+❎enter demo", 1, 1, 6)
    end
    print("demo: " .. demo_i .. " "..demos[demo_i].name, 1, 7, 7)
end

function was_pressed(i)
    return btn(i) and not prev_btn[i + 1]
end