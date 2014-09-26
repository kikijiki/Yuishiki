--- The assets loader.
-- @module summon.AssetLoader

assert(summon, "SUMMON is not loaded.")

local AssetLoader = {}

local assets = {}
local assets_path = "assets/"
local cache = {}

--- Register a type of asset.
-- @param asset The name of the asset type.
-- @param path The default subpath where to search for this type of assets.
-- @param loader The factory function which builds the asset.
-- @param caching The default value for the caching option.
-- @usage Assets.register("texture", "textures", summon.texture.loader)
function AssetLoader.register(asset, path, loader, caching)
  assets[asset] = {
    path = path,
    loader = loader,
    caching = caching}
  cache[asset] = {}
end

function AssetLoader.getAssetPath(asset_type)
  return assets_path..assets[asset_type].path
end

--- Load an asset.
-- @param asset_type The type of asset to load.
-- @param asset_name The filename of the asset (extension included).
-- @param caching Set to false to disable caching for this asset (optional, default = true).
-- @usage Assets.load("texture", "tex0.png")
-- @return the asset.
function AssetLoader.load(asset_type, asset_name, caching)
  assert(asset_type, "Asset type is nil.")
  assert(asset_name, "Asset name is nil.")

  local a = assets[asset_type]
  assert(a, "Resource type \""..asset_type.."\" is unknown.")
  local base_path = assets_path..a.path.."/"
  local path = base_path..asset_name

  caching = caching or a.caching
  if not caching then return AssetLoader.loadDirect(a.loader, path, base_path, asset_name) end
  
  if cache[asset_type][asset_name] then
    return cache[asset_type][asset_name].asset
  else
    local data = AssetLoader.loadDirect(a.loader, path, base_path, asset_name)
    if data then 
      cache[asset_type][asset_name] = {asset = data, path = path}
      return data
    end
  end
end

function AssetLoader.loadDirect(loader, path, base_path, asset_name)
  local ret, buf = pcall(loader, path, base_path, asset_name)
  if ret then 
    return buf
  else
    summon.log.w("Could not load \""..path.."\", error: "..tostring(buf))
    return nil
  end
end

function AssetLoader.loadRaw(path, name, env)
  assert(path, "Path is nil.")
  
  local err, data
  if name then
    local a = assets[path]
    err, data = assert(summon.common.uti.runSandboxed(assets_path..a.path.."/"..name, env))
  else
    err, data = assert(summon.common.uti.runSandboxed(path, env))
  end
  return data
end

--- Clear the cache.
-- Empty all the cache or only part of it.
-- @param asset_type The type of asset to clear, or nil for all.
-- @param asset_name The name of the asset to clear, or nil for all.
function AssetLoader.clear(asset_type, asset_name)
  assert(asset_type, "Asset type is nil.")
  
  if asset_type then
    if asset_name then cache[asset_type][asset_name] = nil
    else cache[asset_type] = {} end
  else
    for k,_ in pairs(cache) do cache[k] = {} end
  end
end

--- Reload one or more assets.
-- @param asset_type The type of the asset to reload.
-- @param asset_name The name of the asset to reload, or nil for all.
function AssetLoader.reload(asset_type, asset_name)
  assert(asset_type, "Asset type is nil.")
  
  local c = cache[asset_type]
  
  if asset_name and c[asset_name].reload then c[asset_name]:reload(path)
  else
    for k,v in pairs(c) do
      if c[k].asset.reload then c[k].asset:reload(v.path) end
    end
  end
end

return AssetLoader