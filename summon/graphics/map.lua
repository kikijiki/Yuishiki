assert(summon, "SUMMON is not loaded.")

local vec = summon.vec
local spritebatch = summon.graphics.sprite.SpriteBatch
local animation = summon.graphics.sprite.Animation
local draw = summon.graphics.draw
local setColor = summon.graphics.setColor
local astar = summon.common.astar

math.randomseed(os.time())

local Map = summon.class("Map")
local Tile = summon.class("Tile")

local tile_id_generator = summon.common.uti.idGenerator("tile")

function Tile:initialize(map, il, ir, data, level)
  self.texture = map.texture
  self.coordinates = vec(il, ir)
  self.height = 0
  self.visible = data[2] or true
  self.walkable = data[3] or true
  self.sync = data[4] or false
  self.neighbors = {all = {}}
  self.id = tile_id_generator()

  if level then for _,p in pairs(level) do table.insert(data[1], p) end end

  self.subtiles = {}
  for _,subtile in pairs(data[1]) do
    local st = {}
    local animationId = map.bindings[subtile]
    st.animation = map.animations[animationId]
    st.index = 1

    if not self.sync then st.elapsed = math.random()
    else st.elapsed = 0 end

    table.insert(self.subtiles, st)

    self.height = self.height + st.animation.height
  end

  self.size = #self.subtiles
end

function Tile:draw()
  local pos = self.position:clone()

  for i = self.size, 1, -1 do
    local st = self.subtiles[i]
    local ani = st.animation
    local frame = ani.frames[st.index]
    local cnt = frame.source.center
    local height = frame.source.height
    local quad = frame.source.quad
    if self.walkable then
      setColor(255, 255, 255, 255)
    else
      setColor(255, 0, 0, 255)
    end
    draw(self.texture.data,
      quad, pos.x - cnt.x,
      pos.y - cnt.y - height)

    pos.y = pos.y - height
  end
end

function Tile:update(dt)
  for _,st in pairs(self.subtiles) do
    st.elapsed, st.index =
      st.animation:update(dt, st.elapsed, st.index)
  end
end

function Map:initialize(name, tileset)
  self.name = name
  self.position = vec(0, 0)
  self.tileset = tileset
  self.texture = tileset.texture
  self.depth = {hstep = 10, sprite = -5}
  self.tiles = {}
  self.grid = {}
  self.animations = {}
  self.aabb = {}
  self.directions = {
    ["NE"] = vec(-1,  0),
    ["NW"] = vec( 0, -1),
    ["SE"] = vec( 0,  1),
    ["SW"] = vec( 1,  0)}
end

function Map.static.load(path)
  assert(path, "Path is nil.")

  local map_data = summon.AssetLoader.loadRaw(path)
  local tileset = summon.AssetLoader.load("spritesheet", map_data.tileset)
  local map = Map(map_data.name, tileset)

  map.prefix = map_data.prefix
  map.bindings = map_data.bindings

  for k,v in pairs(map_data.animations) do
    map.animations[k] = animation.parse(k, v, tileset, true)
  end

  local max = {x = 0, y = 0, h = 0}

  for coord,tile_data in pairs(map_data.tiles) do
    local ir, il = coord[1], coord[2]

    max.x = math.max(max.x, ir)
    max.y = math.max(max.y, il)

    local tile = Tile(map, il, ir, tile_data, map_data.level)
    max.h = math.max(max.h, tile.height)
    map:assignTileCoordinates(tile)

    table.insert(map.tiles, tile)
    if not map.grid[il] then map.grid[il] = {} end
    map.grid[il][ir] = tile
  end

  local function setAdjacency(tile, x, y, dir)
    local c = tile.coordinates
    local n = map.grid[c.x + x]
    if n then n = n[c.y + y] end
    if n then
      tile.neighbors[dir] = n
      table.insert(tile.neighbors.all, n)
    end
  end

  for _,tile in pairs(map.tiles) do
    for dir, coord in pairs(map.directions) do
      setAdjacency(tile, coord.x, coord.y, dir)
    end
  end

  map:computeDepth(max)
  map:computeAABB()
  return map
end

function Map:assignTileCoordinates(t)
  local il = t.coordinates.x - 1
  local ir = t.coordinates.y - 1
  local dx, dy = self.tileset.tileOffset:unpack()

  t.position = vec((ir - il) * dx, (ir + il) * dy)
end

function Map:computeAABB()
  local left, top, right, bottom = 0, 0, 0, 0

  for _,tile in pairs(self.tiles) do
    local i = self:getTilePixelCoordinates(tile.coordinates)
    local dx, dy = self.tileset.tileOffset:unpack()

    left = math.min(i.base.x - dx, left)
    right = math.max(i.base.x + dx, right)
    top = math.min(i.top.y - dy, top)
    bottom = math.max(i.base.y + dy, bottom)
  end

  self.aabb = {
    left = left,
    top = top,
    right = right,
    bottom = bottom,
    width = right - left,
    height = bottom - top }
end

function Map:computeDepth(max)
  local hstep = self.depth.hstep
  local step = max.h * hstep
  local back = (max.x + max.y) * step

  for _,tile in pairs(self.tiles) do
    local x, y = tile.coordinates.x - 1, tile.coordinates.y - 1
    tile.z = back - (x + y) * step - tile.height * hstep
  end

  self.depth.step = step
  self.depth.back = back
end

function Map:draw()
  for _,tile in pairs(self.tiles) do
    spritebatch.add(tile)
  end
end

function Map:update(dt)
  for _,tile in pairs(self.tiles) do
    tile:update(dt)
  end
end

function Map:getTile(v)
  return self.grid[v.x][v.y]
end

function Map:getFacingDirection(from, to)
  local diff = to - from
  local dir

  if diff.x == 0 and diff.y == 0 then return nil end

  if math.abs(diff.x) > math.abs(diff.y) then
    if diff.x > 0 then dir = "SW"
    else dir = "NE" end
  else
    if diff.y > 0 then dir = "SE"
    else dir = "NW" end
  end

  return dir
end

function Map:moveEntity(e, v)
  local coord = e.map_coordinates + v

  if self.grid[coord.y] and self.grid[coord.y][coord.x] then
    e.map_coordinates = coord
    self:place(e)
  end
end

function Map:containsTile(v)
  if self.grid[v.y] and self.grid[v.y][v.x] then return true
  else return false end
end

function Map:setWalkable(v, walkable)
  local tile = self:getTile(v)
  if tile then tile.walkable = walkable end
end

function Map:getTilePixelCoordinates(v)
  local tile = self:getTile(v)
  local top = tile.position:clone()
  local height = 0
  local heightM = 0

  for _,v in pairs(tile.subtiles) do
    local ani = v.animation
    local frame = ani.frames[v.index].source
    top.y = top.y - frame.height
    height = height + frame.height
    heightM = heightM + ani.height
  end

  return {
    base = tile.position,
    top = top,
    height = height,
    heightM = heightM,
    z = tile.z,
    spriteZ = tile.z + self.depth.sprite
  }
end

function Map:pathTo(from, to, out, walkable_only)
  local path = astar(self:getTile(from), self:getTile(to), self.tiles,
    function(tile)
      local ret = {}
      for _,t in pairs(tile.neighbors.all) do
        if walkable_only == false or t.walkable or t.coordinates == from then table.insert(ret, t) end
      end
      return ret
    end,
    function(a, b, n)
      return 1 + math.abs(a.height - b.height) * 10 --a.coordinates:dist2(b.coordinates)
    end,
    function(a, b)
      return a.coordinates:dist2(b.coordinates) + math.abs(a.height - b.height) * 10
    end,
    out
  )
  path = path or {}
  table.remove(path, 1)
  return path
end

function Map:directionsTo(from, to, walkable_only)
  return self:pathTo(from, to, function(tile) return tile.coordinates end)
end

function addTileRecursive(tiles, tile, range, walkable_only)
  tiles[tile] = tile.coordinates
  if range == 0 then return end
  for _,n in pairs(tile.neighbors.all) do
    if walkable_only == false or n.walkable then
      addTileRecursive(tiles, n, range - 1, walkable_only)
    end
  end
end

function Map:getRange(target, range, exclude_target, walkable_only)
  local tiles = {}
  local target_tile = self:getTile(target)
  addTileRecursive(tiles, target_tile, range, walkable_only)
  if exclude_target then tiles[target_tile] = nil end
  local ret = {}
  for _,v in pairs(tiles) do table.insert(ret, v) end
  return ret
end

return Map
