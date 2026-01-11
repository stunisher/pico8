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