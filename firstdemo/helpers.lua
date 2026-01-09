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