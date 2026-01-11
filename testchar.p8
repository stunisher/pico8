pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
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

entities = {}
enemy_defs = {}
function register_enemy(name,f) enemy_defs[name]=f end
function spawn_enemy(name,params)
 local f=enemy_defs[name] if not f then return end
 local e=f(params or {}) spawn_entity(e) return e
end

-- example bird registration
register_enemy('bird', function(p)
 return enemy:new{
  x=p.x or 64, y=p.y or 64,
  spr_idle=37, idle_frames={37,38}, walk_frames={37,38},
  spd=0.8, hp=2, hitbox={'circle',4}, anim=0, anim_speed=12
 }
end)

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
    local sorted = {}
    for e in all(entities) do
        add(sorted, e)
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

class = {}
function class:new(tbl)
    tbl = tbl or {}
    setmetatable(tbl, { __index = self })
    return tbl
end

entity = class:new({
    x = 0, y = 0, spd = 0,
    update = function(self)
        self.x = self.x + self.spd
    end,
    draw = function(self)
        circfill(self.x, self.y, 1, 7)
    end
})

function circle_vs_circle(x1,y1,r1,x2,y2,r2)
 return (x1-x2)^2 + (y1-y2)^2 <= (r1+r2)^2
end

function circle_vs_rect(cx,cy,r, rx,ry,w,h)
 local nx=mid(rx-w/2, cx, rx+w/2)
 local ny=mid(ry-h/2, cy, ry+h/2)
 local dx=cx-nx; local dy=cy-ny
 return dx*dx+dy*dy <= r*r
end

function collides(a,b)
 local ha = a.hitbox or {'circle', (a.r or 4)}
 local hb = b.hitbox or {'circle', (b.r or 4)}
 if ha[1]=='circle' and hb[1]=='circle' then
  return circle_vs_circle(a.x,a.y,ha[2], b.x,b.y,hb[2])
 elseif ha[1]=='circle' and hb[1]=='rect' then
  return circle_vs_rect(a.x,a.y,ha[2], b.x+ (hb[3].ox or 0), b.y+ (hb[3].oy or 0), hb[3].w, hb[3].h)
 elseif ha[1]=='rect' and hb[1]=='circle' then
  return circle_vs_rect(b.x,b.y,hb[2], a.x+ (ha[3].ox or 0), a.y+ (ha[3].oy or 0), ha[3].w, ha[3].h)
 else
  -- rect vs rect
  return abs(a.x-b.x) <= ((ha[3].w/2)+(hb[3].w/2)) and abs(a.y-b.y) <= ((ha[3].h/2)+(hb[3].h/2))
 end
end

function _init()
    player_inst = player:new({})
    -- instance from prototype

    -- spawn a flower at a random on-screen location
    spawn_entity(flower:new({ x = flr(rnd(120)) + 4, y = flr(rnd(120)) + 4 }))
    spawn_entity(stump:new({ x = flr(rnd(120)) + 4, y = flr(rnd(120)) + 4 }))
    spawn_entity(enemy:new({ x=flr(rnd(120))+4, y=flr(rnd(120))+4 }))
    spawn_enemy('bird',{ x=flr(rnd(120))+4, y=flr(rnd(120))+4 })
    spawn_entity(player_inst)
end

function _update60()
    update_entities()
    update_attacks()
end

function _draw()
    cls()
    map()
    draw_attacks('behind')
    draw_entities()
    draw_attacks('front')
end
local SPR_DOWN = 1
local SPR_DOWN_WALK = 2
local SPR_RIGHT_WALK = 3
local SPR_RIGHT_STAND = 4
local SPR_UP = 5
local SPR_UP_WALK = 6

player = entity:new({
    x = 64, y = 64,
    hitbox = { 'circle', 4 },
    spd = 1.5, hp = 10, r = 4,
    atk_cooldown = 20,
    atk_timer = 0,
    atk_range = 10,
    atk_damage = 1,
    update = function(self)
        local dx, dy = 0, 0
        if btn(0) then dx = dx - 1 end
        if btn(1) then dx = dx + 1 end
        if btn(2) then dy = dy - 1 end
        if btn(3) then dy = dy + 1 end

        if btnp(4) and (self.atk_timer or 0) <= 0 then
            self.atk_timer = 12
            local af, aflip = 33, 0
            if self.face == 3 then
                -- down
                af, aflip = 33, 0
            elseif self.face == 1 then
                -- right
                af, aflip = 34, 0
            elseif self.face == 0 then
                -- left
                af, aflip = 34, 1
            elseif self.face == 2 then
                -- up (use frame 35 flipped per request)
                af, aflip = 35, 1
            end
            self.attack_frame = af
            self.attack_flip = aflip

            spawn_attack_by_name('punch', { owner = self, dx = self.last_dx, dy = self.last_dy })
        end

        local l = sqrt(dx * dx + dy * dy)
        if l > 0 then
            self.last_dx, self.last_dy = dx, dy
            -- moving: normalize, animate, move and update facing
            dx, dy = dx / l, dy / l
            self.anim = (self.anim + 1) % 30
            local mx, my = dx * self.spd, dy * self.spd
            try_move(self, mx, 0)
            try_move(self, 0, my)

            if abs(dx) > abs(dy) then
                if dx > 0 then self.face = 1 else self.face = 0 end
            else
                if dy > 0 then self.face = 3 else self.face = 2 end
            end
        else
            -- idle: stop animation but keep last `face`
            self.anim = 0
        end

        self.x = mid(4, self.x, 124)
        self.y = mid(4, self.y, 124)
        if self.atk_timer and self.atk_timer > 0 then self.atk_timer -= 1 end
    end,

    draw = function(self)
        local step = flr(self.anim / 8) % 2
        local frame, flip = SPR_RIGHT_STAND, 0

        if self.face == 0 then
            frame = (step == 0 and SPR_RIGHT_STAND or SPR_RIGHT_WALK)
            flip = 1
        elseif self.face == 1 then
            frame = (step == 0 and SPR_RIGHT_STAND or SPR_RIGHT_WALK)
            flip = 0
        elseif self.face == 2 then
            if self.anim == 0 then frame = SPR_UP else frame = SPR_UP_WALK end
            flip = step
        else
            if self.anim == 0 then frame = SPR_DOWN else frame = SPR_DOWN_WALK end
            flip = step
        end
        if self.atk_timer and self.atk_timer > 0 and self.attack_frame then
            spr(self.attack_frame, self.x - 4, self.y - 4, 1, 1, self.attack_flip == 1)
            return
        end
        spr(frame, self.x - 4, self.y - 4, 1, 1, flip == 1)
    end
})
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00000000000000000000000000000000016250172501825019250292501a2501c2501d2501e2501f2500000020250222502325024250262502725028250232502c25024250242502f25026250322502825029250
000100002165024650206501b6501c15021150291502a150236501e6501b6501d45021450264502a45025600276002360026600276002b6002f60033600383003830038300373003530034300323003130000300
00050000241502a150311503e1503215026150237501c2501825015250152501f6501465006650106501565005650036500065000000006500000000000000000000000000000000000000000000000000000000
