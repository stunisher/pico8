-- demo5: projectiles + targets (step 1: spawn & draw)

function demo5_init()
    -- reuse demo4's bullet/aim setup
    if demo4_init then demo4_init() end

    max_targets = 12

    -- spawn a few test targets
    spawn_target(100, 40, 12, 12, 3)
    spawn_target(100, 80, 14, 14, 4)
    spawn_target(40, 90, 10, 10, 2)
end

function demo5_update()
    -- delegate firing/bullet updates to demo4 update (so bullets still work)
    if demo4_update then demo4_update() end

    -- update targets: movement and respawn
    for t in all(targets) do
        -- flash timer
        if t.flash > 0 then t.flash -= 1 end

        if t.alive then
            -- simple patrol: move horizontally and bounce at bounds (8..120)
            t.x += t.vx
            if t.x < 8 then
                t.x = 8
                t.vx = -t.vx
            elseif t.x + t.w > 120 then
                t.x = 120 - t.w
                t.vx = -t.vx
            end
        else
            -- dead: count down respawn
            if t.respawn > 0 then
                t.respawn -= 1
                if t.respawn <= 0 then
                    -- revive in place (or randomize position)
                    t.alive = true
                    t.hp = t.max_hp
                    t.flash = 6
                    -- randomize vx/direction a bit on respawn
                    t.vx = (rnd() - 0.5) * 0.8
                    -- optionally move to a fresh x,y:
                    -- t.x = 16 + rnd() * 96
                    -- t.y = 20 + rnd() * 88
                end
            end
        end
    end
    update_particles()
end

function demo5_draw()
    -- let demo4 draw bullets and aim first
    if demo4_draw then demo4_draw() end

    -- draw targets on top
    for t in all(targets) do
        if t.alive then
            -- flash effect when recently hit
            local col = t.flash > 0 and 7 or 11
            rectfill(t.x, t.y, t.x + t.w, t.y + t.h, col)
            rect(t.x, t.y, t.x + t.w, t.y + t.h, 8)
            -- draw hp number above the target
            print(t.hp, t.x + 1, t.y - 6, 0)
        else
            -- small dead marker
            rectfill(t.x, t.y, t.x + t.w, t.y + t.h, 0)
            print("dead", t.x, t.y - 6, 7)
        end
    end
    draw_particles()
    print("score: " .. (score or 0), 4, 31, 7)
end