function circle_vs_circle(x1, y1, r1, x2, y2, r2)
    local dx = x1 - x2
    local dy = y1 - y2
    local rsum = r1 + r2
    -- quick axis check to avoid squaring very large numbers (prevents numeric overflow)
    if abs(dx) > rsum or abs(dy) > rsum then return false end
    local rr = rsum * rsum
    return dx * dx + dy * dy <= rr
end

function circle_vs_rect(cx, cy, r, rx, ry, w, h)
    local nx = mid(rx - w / 2, cx, rx + w / 2)
    local ny = mid(ry - h / 2, cy, ry + h / 2)
    local dx = cx - nx
    local dy = cy - ny
    return dx * dx + dy * dy <= r * r
end

function collides(a, b)
    local ha = a.hitbox or { 'circle', (a.r or 4) }
    local hb = b.hitbox or { 'circle', (b.r or 4) }
    if ha[1] == 'circle' and hb[1] == 'circle' then
        return circle_vs_circle(a.x, a.y, ha[2], b.x, b.y, hb[2])
    elseif ha[1] == 'circle' and hb[1] == 'rect' then
        return circle_vs_rect(a.x, a.y, ha[2], b.x + (hb[3].ox or 0), b.y + (hb[3].oy or 0), hb[3].w, hb[3].h)
    elseif ha[1] == 'rect' and hb[1] == 'circle' then
        return circle_vs_rect(b.x, b.y, hb[2], a.x + (ha[3].ox or 0), a.y + (ha[3].oy or 0), ha[3].w, ha[3].h)
    else
        -- rect vs rect (respect offsets)
        local a3 = ha[3] or {}
        local b3 = hb[3] or {}
        local ax = a.x + (a3.ox or 0)
        local ay = a.y + (a3.oy or 0)
        local bx = b.x + (b3.ox or 0)
        local by = b.y + (b3.oy or 0)
        local aw = (a3.w or 0) / 2
        local ah = (a3.h or 0) / 2
        local bw = (b3.w or 0) / 2
        local bh = (b3.h or 0) / 2
        return abs(ax - bx) <= (aw + bw) and abs(ay - by) <= (ah + bh)
    end
end