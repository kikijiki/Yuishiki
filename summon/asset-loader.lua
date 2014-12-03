--- The assets loader.
-- @module summon.AssetLoader

local AssetLoader

return function(loader)
  if AssetLoader then return AssetLoader end

  local log = loader.load "log"
  log = log.tag("AL")
  local uti = loader.load "uti"

  AssetLoader = {}

  AssetLoader.assets      = {}
  AssetLoader.assets_path = "assets/"
  AssetLoader.cache       = {}
  AssetLoader.sandboxed   = true

  --- Register a type of asset.
  -- @param asset The name of the asset type.
  -- @param path The default subpath where to search for this type of assets.
  -- @param loader The factory function which builds the asset.
  -- @param caching The default value for the caching option.
  -- @usage Assets.register("texture", "textures", summon.texture.loader)
  function AssetLoader.register(asset, path, loader, caching)
    AssetLoader.assets[asset] = {
      path = path,
      loader = loader,
      caching = caching}
    AssetLoader.cache[asset] = {}
  end

  function AssetLoader.getAssetPath(asset_type)
    return AssetLoader.assets_path..AssetLoader.assets[asset_type].path
  end

  --- Load an asset.
  -- @param asset_type The type of asset to load.
  -- @param asset_name The filename of the asset (extension included).
  -- @param caching Set to false to disable caching for this asset (optional, default = true).
  -- @usage Assets.load("texture", "tex0.png")
  -- @return the asset.
  function AssetLoader.load(asset_type, asset_name, caching, ...)
    assert(asset_type, "Asset type is nil.")
    assert(asset_name, "Asset name is nil.")

    local a = AssetLoader.assets[asset_type]
    assert(a, "Resource type \""..asset_type.."\" is unknown.")
    local base_path = AssetLoader.assets_path..a.path.."/"
    local path = base_path..asset_name

    caching = caching or a.caching
    if not caching then return AssetLoader.loadDirect(a.loader, path, base_path, asset_name, ...) end

    if AssetLoader.cache[asset_type][asset_name] then
      return AssetLoader.cache[asset_type][asset_name].asset
    else
      local data = AssetLoader.loadDirect(a.loader, path, base_path, asset_name, ...)
      if data then
        AssetLoader.cache[asset_type][asset_name] = {asset = data, path = path}
        return data
      end
    end
  end

  function AssetLoader.loadDirect(loader, path, base_path, asset_name, ...)
    local ret, buf = xpcall(loader,
      function(err)
        log.e("Could not load "..path)
        log.e("Error:\n"..err)
        log.e(debug.traceback())
      end,
      path, base_path, asset_name, ...)

    if ret then return buf end
  end

  function AssetLoader.loadRaw(path, env)
    assert(path, "Path is nil.")

    if AssetLoader.sandboxed then
      local ret, data
      ret, data = uti.runSandboxed(path,
        function(err)
          log.e("Could not load "..path)
          log.e("Error:\n"..err)
          log.e(debug.traceback())
        end,
        env)
      if ret then return data end
    else
      return love.filesystem.load(path)()
    end
  end

  --- Clear the cache.
  -- Empty all the cache or only part of it.
  -- @param asset_type The type of asset to clear, or nil for all.
  -- @param asset_name The name of the asset to clear, or nil for all.
  function AssetLoader.clear(asset_type, asset_name)
    assert(asset_type, "Asset type is nil.")

    if asset_type then
      if asset_name then AssetLoader.cache[asset_type][asset_name] = nil
      else AssetLoader.cache[asset_type] = {} end
    else
      for k,_ in pairs(cache) do AssetLoader.cache[k] = {} end
    end
  end

  --- Reload one or more assets.
  -- @param asset_type The type of the asset to reload.
  -- @param asset_name The name of the asset to reload, or nil for all.
  function AssetLoader.reload(asset_type, asset_name)
    assert(asset_type, "Asset type is nil.")

    local c = AssetLoader.cache[asset_type]

    if asset_name and c[asset_name].reload then c[asset_name]:reload(path)
    else
      for k,v in pairs(c) do
        if c[k].asset.reload then c[k].asset:reload(v.path) end
      end
    end
  end

  return AssetLoader
end
