attacks = {}

function spawn_attack(a) add(attacks, a) end

-- shape handler dispatch (circle, line)
local shape_handlers = {}

shape_handlers.circle = {
    update = function(a)
        a.timer = (a.timer or a.duration) - 1
        local ox = a.x or (a.owner and (a.owner.x + (a.dx or a.owner.last_dx or 1) * (a.offset or 6)))
        local oy = a.y or (a.owner and (a.owner.y + (a.dy or a.owner.last_dy or 0) * (a.offset or 6)))
        local t = 1 - (a.timer / (a.duration or 12))
        local r = (a.min_r or 1) + ((a.max_r or 12) - (a.min_r or 1)) * t
        -- check hits using collides with a transient circle
        for e in all(entities) do
            if e ~= a.owner and not a._hit[e] and collides({ x = ox, y = oy, hitbox = { 'circle', r } }, e) then
                a._hit[e] = true
                if a.on_hit then a.on_hit(a, e) end
            end
        end
    end,
    draw = function(a)
        local ox = a.x or (a.owner and (a.owner.x + (a.dx or a.owner.last_dx or 1) * (a.offset or 6)))
        local oy = a.y or (a.owner and (a.owner.y + (a.dy or a.owner.last_dy or 0) * (a.offset or 6)))
        local t = 1 - (a.timer / (a.duration or 12))
        local r = (a.min_r or 1) + ((a.max_r or 12) - (a.min_r or 1)) * t
        circfill(ox, oy, r, 7)
    end
}

shape_handlers.line = {
    update = function(a)
        a.timer = (a.timer or a.duration) - 1
        local ox, oy = a.x or (a.owner and a.owner.x), a.y or (a.owner and a.owner.y)
        local dx, dy = a.dx or (a.dir_x or 1), a.dy or (a.dir_y or 0)
        local l = sqrt(dx * dx + dy * dy)
        if l == 0 then dx, dy = 1, 0 else dx, dy = dx / l, dy / l end
        local ex, ey = ox + dx * (a.len or 6), oy + dy * (a.len or 6)
        -- test end circle against entities (single-hit per target)
        for e in all(entities) do
            if e ~= a.owner and not a._hit[e] and collides({ x = ex, y = ey, hitbox = { 'circle', a.end_r or 3 } }, e) then
                a._hit[e] = true
                if a.on_hit then a.on_hit(a, e) end
            end
        end
    end,
    draw = function(a)
        local ox, oy = a.x or (a.owner and a.owner.x), a.y or (a.owner and a.owner.y)
        local dx, dy = a.dx or (a.dir_x or 1), a.dy or (a.dir_y or 0)
        local l = sqrt(dx * dx + dy * dy)
        if l == 0 then dx, dy = 1, 0 else dx, dy = dx / l, dy / l end
        local ex, ey = ox + dx * (a.len or 6), oy + dy * (a.len or 6)
        local w = a.w or 3
        for i = -flr(w / 2), flr(w / 2) do
            line(ox + i, oy, ex + i, ey, 7)
        end
        circfill(ex, ey, a.end_r or 3, 7)
    end
}

-- generic attack prototype
attack = {}
function attack:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.timer = o.duration or 12
    o._hit = {}
    o.shape = o.shape or 'circle'
    if o.behind_owner == nil then o.behind_owner = true end
    return o
end

function attack:update()
    local h = shape_handlers[self.shape]
    if h and h.update then h.update(self) end
end

function attack:draw()
    local h = shape_handlers[self.shape]
    if h and h.draw then h.draw(self) end
end

-- manager loops
function update_attacks()
    for i = #attacks, 1, -1 do
        local a = attacks[i]
        a:update()
        if a.timer <= 0 then deli(attacks, i) end
    end
end

function draw_attacks(phase)
    for a in all(attacks) do
        if phase == 'behind' then
            if a.behind_owner then a:draw() end
        else
            if not a.behind_owner then a:draw() end
        end
    end
end

attacks_defs = {}

function register_attack(name, factory)
    attacks_defs[name] = factory
end

function spawn_attack_by_name(name, params)
    local f = attacks_defs[name]
    if not f then return end
    local a = f(params or {})
    spawn_attack(a)
    return a
end

register_attack(
    'punch', function(p)
        local behind = p.behind_owner
        if behind == nil and p.owner then
            -- default: behind unless facing down (face==3)
            behind = (p.owner.face ~= 3)
        end
        return attack:new {
            owner = p.owner,
            shape = 'circle',
            dx = p.dx, dy = p.dy,
            offset = p.offset or 6,
            min_r = p.min_r or 1, max_r = p.max_r or 7,
            duration = p.duration or 8,
            behind_owner = behind,
            on_hit = p.on_hit or function(a, e) e.hp = (e.hp or 1) - 1 if e.hp <= 0 then e.dead = true end end
        }
    end
)