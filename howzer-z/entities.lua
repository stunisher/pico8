entities = {}
enemy_defs = {}
function register_enemy(name, f) enemy_defs[name] = f end
function spawn_enemy(name, params)
    local f = enemy_defs[name]
    if not f then return end
    local e = f(params or {})
    spawn_entity(e)
    return e
end

-- example bird registration
register_enemy(
    'bird', function(p)
        return enemy:new {
            x = p.x or 64, y = p.y or 64,
            spr_idle = 37, idle_frames = { 37, 38 }, walk_frames = { 37, 38 },
            spd = 0.8, hp = 2, hitbox = { 'circle', 4 }, anim = 0, anim_speed = 12
        }
    end
)

spawn_entity = function(e)
    add(entities, e)
end

update_entities = function()
    -- iterate backwards so we can remove dead entities safely
    for i = #entities, 1, -1 do
        local o = entities[i]
        o:update()
        if o.dead then deli(entities, i) end
    end
end

draw_entities = function()
    local bg = {}
    local fg = {}
    for e in all(entities) do
        if e.bg then add(bg, e) else add(fg, e) end
    end

    local function draw_sorted(list)
        local sorted = {}
        for v in all(list) do
            add(sorted, v)
        end
        for i = 2, #sorted do
            local v = sorted[i] local j = i - 1
            while j > 0 and sorted[j].y > v.y do
                sorted[j + 1] = sorted[j] j = j - 1
            end
            sorted[j + 1] = v
        end
        for o in all(sorted) do
            o:draw()
        end
    end

    draw_sorted(bg)
    -- draw background decor first
    draw_sorted(fg)
    -- then draw foreground (player, enemies, base...)
end

-- simple flower archetype (keeps entities together instead of separate files)
flower = entity:new({
    x = 0, y = 0, type = 'flower',
    hitbox = { 'rect', nil, { w = 6, h = 8, ox = 0, oy = 0 } },
    update = function(self)
        if player_inst and collides(self, player_inst) then
            self.dead = true
        end
    end,
    draw = function(self) spr(19, self.x - 4, self.y - 4) end
})

stump = entity:new({
    x = 0, y = 0, type = 'stump', hp = 5, solid = true,
    hitbox = { 'rect', nil, { w = 6, h = 3, ox = 0, oy = 1 } },
    update = function(self) end,
    draw = function(self) spr(16, self.x - 4, self.y - 4) end
})

base = entity:new({
    x = 64, y = 64, type = 'base', hp = 50, max_hp = 50, sprite = 32,
    update = function(self) end,
    draw = function(self) spr(self.sprite, self.x - 4, self.y - 4) end
})

enemy = entity:new({
    x = 0, y = 0, type = 'enemy', hp = 3, spd = 0.6, dmg = 1,
    hitbox = { 'circle', 5 },

    -- sprite/animation config:
    -- use either single numbers or tables of frame indices for walk_frames
    spr_idle = 36,
    walk_frames = { 36 }, -- one or two frames
    anim = 0,
    anim_speed = 6, -- ticks per frame
    flip = 0,

    attack_cooldown = 30, attack_timer = 0,

    update = function(self)
        if not player_inst then return end

        -- chase player
        local dx, dy = player_inst.x - self.x, player_inst.y - self.y
        local l = sqrt(dx * dx + dy * dy)
        if l > 0 then dx, dy = dx / l, dy / l end

        -- movement & per-axis collision
        try_move(self, dx * self.spd, 0)
        try_move(self, 0, dy * self.spd)

        -- set flip based on horizontal movement
        if dx < -0.01 then
            self.flip = 0
        elseif dx > 0.01 then
            self.flip = 1
        end

        local moving = abs(dx) > 0.01 or abs(dy) > 0.01
        local maxf = max(#(self.walk_frames or {}), #(self.idle_frames or {}))
        if maxf > 1 then
            self.anim = (self.anim + 1) % (maxf * self.anim_speed)
        else
            self.anim = 0
        end

        -- advance animation only if there are multiple walk frames
        if abs(dx) > 0.01 or abs(dy) > 0.01 then
            if type(self.walk_frames) == 'table' and #self.walk_frames > 1 then
                self.anim = (self.anim + 1) % (#self.walk_frames * self.anim_speed)
            else
                self.anim = 0
            end
        else
            self.anim = 0
        end

        -- attack on contact with cooldown
        if collides(self, player_inst) then
            if (self.attack_timer or 0) <= 0 then
                player_inst.hp = (player_inst.hp or 1) - self.dmg
                self.attack_timer = self.attack_cooldown
            end
        end
        if self.attack_timer and self.attack_timer > 0 then self.attack_timer -= 1 end
    end,

    draw = function(self)
        local frames = (moving and (self.walk_frames or {})) or (self.idle_frames or {})
        if type(frames) ~= 'table' or #frames == 0 then frames = { self.spr_idle } end
        local frame = frames[1]
        if #frames > 1 then
            local idx = flr(self.anim / self.anim_speed) % #frames + 1
            frame = frames[idx]
        end
        spr(frame, self.x - 4, self.y - 4, 1, 1, self.flip == 1)
    end
})

function try_move(ent, dx, dy)
    local ox, oy = ent.x, ent.y
    ent.x = ent.x + dx
    for e in all(entities) do
        if e ~= ent and e.solid and not e.dead and collides(ent, e) then
            ent.x = ox break
        end
    end
    ent.y = ent.y + dy
    for e in all(entities) do
        if e ~= ent and e.solid and not e.dead and collides(ent, e) then
            ent.y = oy break
        end
    end
end