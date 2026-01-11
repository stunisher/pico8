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