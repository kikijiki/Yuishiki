local actions = {}

actions["move"] = {
  async = true,
  cost = function(gm, c, path)
    local step_cost = c.status.mov:get()
    return step_cost * #path
  end,
  body = function(gm, c, path)
    return gm:applyRule("move-character", c, path)
  end
}

actions["getPathTo"] = {
  body = function(gm, c, destination, aplimit)
    local map = gm.world.map
    if not destination then return end
    destination = map:getNearestPoint(destination)
    local full_path = map:directionsTo(c.status.position:get(), destination)
    local step_cost = c.status.mov:get()
    local path = {}

    if aplimit then
      local maxlength = math.floor(c.status.ap:get() / step_cost)
      for i = 1, maxlength do path[i] = full_path[i] end
      return path, full_path, step_cost * #path, step_cost
    else
      path = full_path
    end

    return path, full_path, step_cost * #path, step_cost
  end
}

actions["attack"] = {
  async = true,
  cost = function(gm, c, target)
    target = gm:getCharacter(target)
    local weapon = c.equipment:get("weapon")
    if not weapon then return 0 end
    return weapon:getCost(gm, c, target)
  end,
  condition = function(gm, c, target)
    target = gm:getCharacter(target)
    local weapon = c.equipment:get("weapon")
    if not weapon then return false end

    local distance = gm:getCharacterDistance(c, target)
    return weapon.range >= distance
  end,
  body = function(gm, c, target)
    local hit, damage
    target = gm:getCharacter(target)
    local atk_dir = gm:getAttackDirection(c, target)

    c:pushCommand("animation", "attack", {
      tags = {
        ["hit"] = function()
          hit, damage = gm:applyRule("physical-attack", c, target)
          if hit then
            if damage then target:hit(damage, atk_dir)
            else c:bubble("no damage", atk_dir) end
          else c:bubble("miss", atk_dir) end
        end
      }})
    c:pushCommand("lookAt", target)
    target:pushCommand("lookAt", c)

    coroutine.yield()
    return damage
  end,
  meta = function(gm, c, target)
    local weapon = c.equipment:get("weapon")
    target = gm:getCharacter(target)
    return {
      cost = weapon:getCost(gm, c, target),
      damage = {
        max = weapon:maxDamage(gm, c, target),
        min = weapon:minDamage(gm, c, target),
      }
    }
  end
}

actions["endTurn"] = {
  body = function(gm, c)
    return gm:nextCharacter()
  end
}

actions["getRange"] = {
  body = function(gm, c, target, range, exclude_target, walkable_only)
    local map = gm.world.map
    return map:getRange(target, range, exclude_target, walkable_only)
  end
}

actions["isInRange"] = {
  body = function(gm, c, target, range)
    local pos = c.status.position:get()
    local dist = math.abs(pos.x - target.x) + math.abs(pos.y - target.y)
    return dist <= range
  end
}

actions["getDistance"] = {
  body = function(gm, c, target)
    local pos = c.status.position:get()
    return math.abs(pos.x - target.x) + math.abs(pos.y - target.y)
  end
}

actions["getFarthest"] = {
  body = function(gm, c, target, currentAP, walkable_only)
    local map = gm.world.map
    local pos = c.status.position:get()
    local step_cost = c.status.mov:get()
    local maxlength = math.floor(c.status.ap:get() / step_cost)
    local farthest

    for _,tile in pairs(map.tiles) do
      if walkable_only == false or tile.walkable then
        local co = tile.coordinates
        local path = map:pathTo(pos, co, nil, true)
        if not (currentAP == true and #path > maxlength) then
          local distance = math.abs(co.x - target.x) + math.abs(co.y - target.y)
          if not farthest or farthest.distance < distance then
            farthest = {
              position = tile.coordinates,
              distance = distance,
              path = path
            }
          end
        end
      end
    end

    gm.logc(c, farthest.position, farthest.distance, #farthest.path)

    return farthest.position
  end
}

actions["getClosestInRange"] = {
  body = function(gm, c, target, range, exclude_target, walkable_only)
    local map = gm.world.map
    local pos = c.status.position:get()
    local candidates = gm:executeAction(c,
      "getRange", target, range, exclude_target, walkable_only)
    if not candidates or #candidates == 0 then return end
    local nearest = nil
    local nearest_distance = -1
    for tile,coordinates in pairs(candidates) do
      local path = map:pathTo(pos, coordinates, nil, walkable_only)
      if not nearest or #path < nearest_distance then
        nearest = coordinates
        nearest_distance = #path
      end
    end
    return nearest
  end
}

return {
  actions = actions
}
