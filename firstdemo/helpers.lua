prev_btn = { false, false, false, false, false, false }
targets = {}

function fmt(n, d)
    local p = 10 ^ (d or 2)
    return (flr(n * p + 0.5) / p)
end

function normalize(dx,dy)
  local l = sqrt(dx*dx + dy*dy)
  if l > 0 then return dx / l, dy / l end
  return 0,0
end

function was_pressed(i)
    return btn(i) and not prev_btn[i + 1]
end

-- closest-point circle-vs-rect test
function circle_vs_rect(bx, by, br, rx, ry, rw, rh)
    -- find closest point on rect to circle center
    local cx = bx
    if cx < rx then cx = rx end
    if cx > rx + rw then cx = rx + rw end

    local cy = by
    if cy < ry then cy = ry end
    if cy > ry + rh then cy = ry + rh end

    local dx = bx - cx
    local dy = by - cy
    return dx * dx + dy * dy <= br * br
end

-- simple particle pool for hit effect
particles = particles or {}

function spawn_hit_particle(x, y, life)
    -- reuse dead particle or add
    local i
    for j = 1, #particles do
        if particles[j].life <= 0 then
            i = j break
        end
    end
    if not i then
        i = #particles + 1
        particles[i] = { x = 0, y = 0, vx = 0, vy = 0, life = 0 }
    end
    particles[i].x = x
    particles[i].y = y
    particles[i].vx = (rnd() - 0.5) * 1.6
    particles[i].vy = (rnd() - 0.5) * 1.6
    particles[i].life = life or 12
end

function update_particles()
    for p in all(particles) do
        if p.life > 0 then
            p.x += p.vx
            p.y += p.vy
            p.vy += 0.04 -- tiny gravity on particles
            p.life -= 1
        end
    end
end

function draw_particles()
    for p in all(particles) do
        if p.life > 0 then
            local col = 8
            circfill(p.x, p.y, 1, col)
        end
    end
end

function spawn_target(x, y, w, h, hp, vx)
    local t = {
        x = x,
        y = y,
        w = w or 12,
        h = h or 12,
        hp = hp or 3,
        max_hp = hp or 3,   -- remember original hp for respawn
        alive = true,
        flash = 0,
        vx = vx or (rnd() - 0.5) * 0.8, -- small random patrol speed if not provided
        respawn = 0
    }
    add(targets, t)
    return t
end