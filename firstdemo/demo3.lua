function demo3_init()
  cx, cy = 64, 64
  a = 0              -- angle (radians)
  px, py = cx, cy    -- moving point
  r = 30             -- circle radius for orbit visualization
  move_speed = 1.1
  rot_speed = 0.05
  arrow_scale = 14
  orbit_mode = true  -- toggle: orbit vs free-move

  params3 = {
    {name="move_speed", val=move_speed, step=0.1, min=0.1, max=6},
    {name="rot_speed",  val=rot_speed,  step=0.01, min=0.01, max=1},
    {name="r",          val=r,          step=1,   min=4,   max=60},
    {name="arrow_scale",val=arrow_scale,step=1,   min=4,   max=32}
  }
  param3_i = 1
end

function demo3_update()
  -- PARAM MODE: hold O (btn4)
  if btn(4) then
    if was_pressed(0) then param3_i = (param3_i - 2) % #params3 + 1 end
    if was_pressed(1) then param3_i = (param3_i) % #params3 + 1 end
    if was_pressed(2) then params3[param3_i].val = min(params3[param3_i].max, params3[param3_i].val + params3[param3_i].step) end
    if was_pressed(3) then params3[param3_i].val = max(params3[param3_i].min, params3[param3_i].val - params3[param3_i].step) end

    -- sync to locals (simple)
    move_speed = params3[1].val
    rot_speed  = params3[2].val
    r          = params3[3].val
    arrow_scale= params3[4].val

    return -- skip normal controls while editing
  end

  -- rotation controls
  if btn(0) then a += rot_speed end -- left: rotate ccw
  if btn(1) then a -= rot_speed end -- right: rotate cw

  -- forward/back along angle
  local vx = cos(a)
  local vy = sin(a)
  if btn(2) then -- up = forward
    if orbit_mode then
      -- if orbit_mode, just spin (advance angle) or move radius
      a -= rot_speed -- small spin on up for orbit-mode, or leave empty
    else
      px += vx * move_speed
      py += vy * move_speed
    end
  end
  if btn(3) then -- down = backward
    if not orbit_mode then
      px -= vx * move_speed
      py -= vy * move_speed
    end
  end

  -- toggle orbit/free-mode with X (btn5) single-press
  if was_pressed(5) then orbit_mode = not orbit_mode end

  -- if orbit mode, compute position from angle & radius
  if orbit_mode then
    px = cx + cos(a) * r
    py = cy + sin(a) * r
  end

  -- clamp px/py to screen bounds (optional)
  px = mid(0, px, 127)
  py = mid(0, py, 127)
end

function demo3_draw()
  -- background
  cls()

  -- unit circle
  circ(cx, cy, r, 6)
  -- arrow from center showing direction
  local ax = cx + cos(a) * arrow_scale
  local ay = cy + sin(a) * arrow_scale
  line(cx, cy, ax, ay, 8)
  circfill(ax, ay, 2, 8)

  -- draw the moving point
  circfill(px, py, 3, 7)

  -- rotate a local point example: a small rectangle at local (12,0)
  local lx, ly = 12, 0
  local rx = cx + cos(a) * lx - sin(a) * ly
  local ry = cy + sin(a) * lx + cos(a) * ly
  rectfill(rx-2, ry-2, rx+2, ry+2, 11)

  -- HUD
  local deg = a * 180 / 3.141592653589793
  print("angle:"..fmt(a,3).." rad", 1, 13, 7)
  print("deg:"..fmt(deg,2), 1, 19, 7)
  print("vx:"..fmt(cos(a),3).." vy:"..fmt(sin(a),3), 1, 25, 7)
  print("orbit:"..(orbit_mode and "on" or "off").."  press X to toggle", 1, 31, 6)

  -- param HUD when holding O (btn4) will be drawn by update logic (or you can draw it here)
  if btn(4) then
    local p = params3[param3_i]
    print("PARAM MODE", 1, 37, 8)
    print(p.name .. ": " .. tostring(fmt(p.val,3)), 1, 43, 7)
  end
end

function normalize(dx,dy)
  local l = sqrt(dx*dx + dy*dy)
  if l > 0 then return dx / l, dy / l end
  return 0,0
end