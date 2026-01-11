local SPR_DOWN = 1
local SPR_DOWN_WALK = 2
local SPR_RIGHT_WALK = 3
local SPR_RIGHT_STAND = 4
local SPR_UP = 5
local SPR_UP_WALK = 6

player = entity:new({
    x = 64, y = 64,
    hitbox = { 'circle', 4 },
    spd = 1.1, hp = 10, r = 4,
    atk_cooldown = 20,
    atk_timer = 0,
    atk_range = 10,
    atk_damage = 1,
    anim = 0, face = 3,
    update = function(self)
        local dx, dy = 0, 0
        if inv_open then
            if btnp(0) then inv_sel = max(1, inv_sel - 1) end
            if btnp(1) then inv_sel = min(3, inv_sel + 1) end
            if not btn(5) then
                inv_open = false inv_hold = 0
            end
            self.anim = 0
            return
        end
        if scene == "outdoors" then
            if btn(5) then inv_hold = min(20, inv_hold + 1) else inv_hold = 0 end
            if inv_hold >= 10 then inv_open = true end
        end
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

        if scene == "indoors" then
            local ox, oy = 64 - 20, 64 - 20
            local minx, maxx = ox + 8 + 4, ox + 32 - 4
            local miny = oy + 8 + 4
            local doorcx = ox + 2 * 8 + 4
            local maxy = oy + 3 * 8 + 4
            if abs(self.x - doorcx) <= 4 then maxy = oy + 4 * 8 + 4 end
            self.x = mid(minx, self.x, maxx)
            self.y = mid(miny, self.y, maxy)
            local doorcy = oy + 4 * 8 + 4
            if btnp(5) and abs(self.x - doorcx) <= 4 and abs(self.y - doorcy) <= 6 then
                scene = "outdoors"
                day = (day or 0) + 1
                request_outdoor_reset()
                return
            end
        else
            self.x = mid(4, self.x, (map_w_tiles * 8) - 4)
            self.y = mid(4, self.y, (map_h_tiles * 8) - 4)
        end
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