function demo4_init()
  -- aim / firing state
  ax, ay = 64, 64
  -- aim origin (center)
  aim_angle = 0
  -- radians
  fire_timer = 0
  -- frames until next shot allowed

  bullets = {}
  -- active bullets (pool)
  max_bullets = 64

  -- params: bullet_speed, lifetime (frames), cooldown (frames), spread (deg), gravity
  params4 = {
    { name = "speed", val = 3.5, step = 0.1, min = 0.5, max = 12 },
    { name = "life", val = 60, step = 1, min = 4, max = 300 },
    { name = "cool", val = 6, step = 1, min = 1, max = 30 }, -- frames between shots
    { name = "spread", val = 6, step = 1, min = 0, max = 45 }, -- degrees
    { name = "grav", val = 0, step = 0.005, min = 0, max = 1 } -- gravity per frame applied to vy
  }
  param4_i = 1
end

function spawn_bullet(x, y, angle)
  -- find dead slot
  local i = nil
  for j = 1, #bullets do
    if bullets[j].life <= 0 then
      i = j break
    end
  end
  if not i and #bullets < max_bullets then
    i = #bullets + 1
    bullets[i] = { x = 0, y = 0, vx = 0, vy = 0, life = 0 }
  end
  if not i then return end

  local speed = params4[1].val
  local spread = params4[4].val * (3.14159265 / 180)
  -- degrees -> radians
  local ang = angle + (rnd() - 0.5) * spread

  bullets[i].x = x
  bullets[i].y = y
  bullets[i].vx = cos(ang) * speed
  bullets[i].vy = sin(ang) * speed
  bullets[i].life = params4[2].val
end

function demo4_update()
  -- PARAM MODE: hold O (btn4)
  if btn(4) then
    if was_pressed(0) then param4_i = (param4_i - 2) % #params4 + 1 end
    if was_pressed(1) then param4_i = param4_i % #params4 + 1 end
    if was_pressed(2) then params4[param4_i].val = min(params4[param4_i].max, params4[param4_i].val + params4[param4_i].step) end
    if was_pressed(3) then params4[param4_i].val = max(params4[param4_i].min, params4[param4_i].val - params4[param4_i].step) end
    return
  end

  -- aim control
  if btn(0) then aim_angle += 0.02 end
  if btn(1) then aim_angle -= 0.02 end

  -- firing (btn5)
  if fire_timer > 0 then fire_timer -= 1 end
  if btn(5) and fire_timer <= 0 then
    spawn_bullet(ax, ay, aim_angle)
    fire_timer = params4[3].val -- cooldown in frames
  end

  -- update bullets
  for i = 1, #bullets do
    local b = bullets[i]
    if b.life > 0 then
      -- apply gravity (param)
      b.vy += params4[5].val
      b.x += b.vx
      b.y += b.vy
      b.life -= 1

      -- offscreen kill
      if b.x < -8 or b.x > 135 or b.y < -8 or b.y > 135 then b.life = 0 end

      -- collision test against targets (only if targets table exists)
      if b.life > 0 and targets then
        for j = 1, #targets do
          local t = targets[j]
          if t and t.alive then
            -- use a small bullet radius, e.g. 1.5
            if circle_vs_rect(b.x, b.y, 1.5, t.x, t.y, t.w, t.h) then
              -- hit reaction
              b.life = 0 -- remove bullet
              t.hp -= 1 -- damage target
              t.flash = 6 -- brief flash for visual feedback
              if t.hp <= 0 then
                t.alive = false
                t.respawn = 180 -- respawn after 3 seconds (180 frames)
                score = (score or 0) + 1 -- increment global score
                -- spawn more particles on death
                for k = 1, 6 do
                  spawn_hit_particle(t.x + t.w / 2, t.y + t.h / 2, 12)
                end
                sfx(2)
              else
                for k = 1, 3 do
                  spawn_hit_particle(b.x, b.y, 8)
                end
                sfx(1)
              end
              break -- stop checking other targets for this bullet
            end
          end
        end
      end
    end
  end
end

function demo4_draw()
  cls()
  -- draw origin / aim arrow
  circfill(ax, ay, 3, 12)
  local ax2 = ax + cos(aim_angle) * 18
  local ay2 = ay + sin(aim_angle) * 18
  line(ax, ay, ax2, ay2, 8)
  circfill(ax2, ay2, 2, 8)

  -- draw bullets
  local count = 0
  for i = 1, #bullets do
    local b = bullets[i]
    if b.life > 0 then
      circfill(b.x, b.y, 1, 7)
      -- optional tiny trail:
      pset(b.x, b.y, 6)
      count += 1
    end
  end

  -- HUD
  print("cooldown:" .. fmt(params4[3].val, 0) .. " fire_t:" .. fire_timer, 1, 13, 7)
  print("hold O to edit params", 1, 19, 6)
  if btn(4) then
    local p = params4[param4_i]
    print("PARAM: " .. p.name .. " = " .. tostr(fmt(p.val, 3)), 1, 25, 8)
  end
end