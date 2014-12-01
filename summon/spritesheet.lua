local SpriteSheet

return function(loader)
  if SpriteSheet then return SpriteSheet end
  local sg          = loader.require "graphics"
  local vec         = loader.require "vector"
  local AssetLoader = loader.load "asset-loader"

  SpriteSheet = loader.class("SpriteSheet")

  local newQuad = sg.newQuad

  function SpriteSheet:initialize(texture)
    self.texture = texture
    self.frames = {}
  end

  function SpriteSheet.static.load(path)
    local data = AssetLoader.loadRaw(path)
    local texture = AssetLoader.load("texture", data.texture)
    local ss = SpriteSheet(texture)

    ss.source = path
    if data.tileOffset then ss.tileOffset = vec(data.tileOffset[1], data.tileOffset[2]) end
    if data.filter then ss.filter = data.filter end

    if ss.filter then ss.texture:setFilter(ss.filter.min, ss.filter.mag) end

    for k,v in pairs(data.frames) do
      local f = {}

      local position = vec(v[1][1], v[1][2])
      local size = vec(v[1][3], v[1][4])

      f.rect = {position = position, size = size}
      f.center = vec(v[2][1], v[2][2])
      f.tags = {}

      if v.tags then
        for k,tag in pairs(v.tags) do
          f.tags[k] = {}
          if tag.left then
            f.tags[k].left = {
              position = vec(tag.left[1][1], tag.left[1][2]),
              z = tag.left[2]}
            f.tags[k].right = {
              position = vec(tag.right[1][1], tag.right[1][2]),
              z = tag.right[2]}
          else
            f.tags[k].position = vec(tag[1][1], tag[1][2])
            f.tags[k].z = tag[2]
          end
        end
      end

      if v.height then f.height = v.height end

      f.quad = newQuad(
        position.x, position.y, size.x, size.y,
        ss.texture:getWidth(), ss.texture:getHeight())

      ss.frames[k] = f
    end

    return ss
  end

  function SpriteSheet:getFrame(id)
    return self.frames[id]
  end

  return SpriteSheet
end
