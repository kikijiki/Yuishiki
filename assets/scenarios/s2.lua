local function setupFactions(characters, factions, protect)
  local function setAllies(faction_id, char_id)
    local char = characters[char_id]
    local faction = factions[faction_id]
    for _, c2 in pairs(faction) do
      if char_id ~= c2 then
        char.agent:setBeliefLT("ally", "characters", c2, "faction")
        if protect then
          char.agent:pushGoal("protect-character", {target = c2})
        end
      end
    end
  end

  local function setEnemies(faction_id, char_id)
    local char = characters[char_id]
    local faction = factions[faction_id]
    for other_faction_id, other_faction in pairs(factions) do
      if other_faction_id ~= faction_id then
        for _, c2 in pairs(other_faction) do
          char.agent:setBeliefLT("enemy", "characters", c2, "faction")
          char.agent:pushGoal("defeat-character", {target = c2})
        end
      end
    end
  end

  local function forAll(f)
    for faction_id,faction in pairs(factions) do
      for _, char_id in pairs(faction) do
        f(faction_id, char_id)
      end
    end
  end

  forAll(setAllies)
  forAll(setEnemies)
end

local stage1 =
{
  map = "map0.lua",
  rules = "r0",
  characters = {
    [ "onimaru"] = { "file",  "onimaru.lua" },
    ["hikoichi"] = { "file", "hikoichi.lua" },
    [    "oni1"] = { "file",      "oni.lua" },
    [    "oni2"] = { "file",      "oni.lua" }
  },
  init = function(stage, world, char)
    world:placeCharacter( "onimaru", 2, 6, "NW")
    world:placeCharacter("hikoichi", 6, 6, "NW")
    world:placeCharacter(    "oni1", 2, 3, "SE")
    world:placeCharacter(    "oni2", 6, 3, "SE")

    setupFactions(char, {
        ninja = {"onimaru", "hikoichi"},
        oni   = {"oni1", "oni2"}
      },
    false)

    char[ "onimaru"].agent:setBeliefLT(true, "no-cooperation")
    char["hikoichi"].agent:setBeliefLT(true, "no-cooperation")
  end
}

local stage2 =
{
  map = "map0.lua",
  rules = "r0",
  characters = {
    [ "onimaru"] = { "file",  "onimaru.lua" },
    ["hikoichi"] = { "file", "hikoichi.lua" },
    [    "oni1"] = { "file",      "oni.lua" },
    [    "oni2"] = { "file",      "oni.lua" }
  },
  init = function(stage, world, char)
    world:placeCharacter( "onimaru", 2, 6, "NW")
    world:placeCharacter("hikoichi", 6, 6, "NW")
    world:placeCharacter(    "oni1", 2, 3, "SE")
    world:placeCharacter(    "oni2", 6, 3, "SE")

    setupFactions(char, {
        ninja = {"onimaru", "hikoichi"},
        oni   = {"oni1", "oni2"}
      },
    true)
  end
}

return
{
  name = {
    en = "Scenario 2",
    ja = "シナリオ２",
    it = "Scenario 2"
  },
  description = {
    en = [[
      Characters: Onimaru, Hikoichi, Oni

      Phases: 1

      Questions: Q3, Q4
    ]],
    ja = [[
      登場人物：　オニマル、ヒコイチ、鬼

      フェーズ数：　１

      アンケート：　Q3、　Q4
    ]],
    it = [[
      Personaggi: Onimaru, Hikoichi, Oni

      Fasi: 1

      Domande: Q3, Q4
    ]],
  },
  phases =
  {
    { "message",
      title = {
        en = "Phase 1",
        ja = "第一フェーズ"
      },
      message = {
        en = [[Onimaru and Hikoichi fight against 2 oni.]],
        ja = [[オニマルとヒコイチが鬼2匹と戦う。]],
        it = [[Onimaru e Hikoichi combattono contro 2 oni.]]
      }
    },
    { "battle",
      title = {
        en = "Phase1",
        ja = "第一フェーズ",
        it = "Fase 1"
      },
      description = {
        en = "Onimaru and Hikoichi fight against 2 oni.",
        ja = "オニマルとヒコイチが鬼2匹と戦う。",
        it = "Onimaru e Hikoichi combattono contro 2 oni."
      },
      stages = { stage1, stage2 }
    }
  }
}
