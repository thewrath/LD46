module = "utils"

local utils = {}

function utils.rect_collision(xa, ya, wa, ha, xb, yb, wb, hb)
  return (xa < xb + wb and xa + wa > xb and ya < yb + hb and ha + ya > yb)
end

return utils