function _init()
    demo_i = 1
    demo_count = 2
    in_demo = false
    prev_btn = { false, false, false, false, false, false }
    demo1_init()
    demo2_init()
end

function _update60()
    if (btn(4) and was_pressed(5)) or (btn(5) and was_pressed(4)) then
        in_demo = not in_demo
    end

    if not in_demo then
        if was_pressed(0) then
            demo_i -= 1
            if demo_i < 1 then demo_i = demo_count end
        elseif was_pressed(1) then
            demo_i += 1
            if demo_i > demo_count then demo_i = 1 end
        end
    elseif in_demo then
        if demo_i == 1 then
            demo1_update()
        elseif demo_i == 2 then
            demo2_update()
        end
    end

    for i = 0, 5 do
        prev_btn[i + 1] = btn(i)
    end
end

function _draw()
    cls()
    if in_demo then
        print("🅾️ + ❎ exit demo", 1, 1, 6)
    else
        print("🅾️ + ❎ enter demo", 1, 1, 6)
    end
    if demo_i == 1 then
        demo1_draw()
    elseif demo_i == 2 then
        demo2_draw()
    end
end

function was_pressed(i)
    return btn(i) and not prev_btn[i + 1]
end