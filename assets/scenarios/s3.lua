local function setupFactions(characters, factions)
  local function setAllies(faction_id, char_id)
    local faction = factions[faction_id]
    local char = characters[char_id]
    for _, c2 in pairs(faction) do
      if char_id ~= c2 then
        char.agent:setBeliefLT("ally", "characters", c2, "faction")
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
          if faction_id == "oni" then -- Only oni immediately want to attack.
            char.agent:pushGoal("defeat-character", {target = c2})
          end
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

local stage1A =
{
  map = "map0.lua",
  rules = "r0",
  characters = {
    ["a_captain"] = { "file", "captain-brave.lua" },
    ["a_ninja1"]  = { "file",         "ninja.lua" },
    ["a_ninja2"]  = { "file",         "ninja.lua" },
    ["a_oni1"]    = { "file",           "oni.lua" },
    ["a_oni2"]    = { "file",           "oni.lua" }
  },
  init = function(stage, world, char)
    setupFactions(char, {
      ninja = {"a_captain", "a_ninja1", "a_ninja2"},
      oni   = {"a_oni1", "a_oni2"}
    })

    world:placeCharacter("a_captain", 4, 6, "NW")
    world:placeCharacter( "a_ninja1", 3, 5, "NW")
    world:placeCharacter( "a_ninja2", 5, 5, "NW")
    world:placeCharacter(   "a_oni1", 3, 2, "SE")
    world:placeCharacter(   "a_oni2", 4, 2, "SE")

    char["a_captain"].agent:pushGoal("defeat-all-enemies")
  end
}

local stage1B =
{
  map = "map0.lua",
  rules = "r0",
  characters = {
    ["b_captain"] = { "file", "captain-coward.lua" },
    ["b_ninja1"]  = { "file",          "ninja.lua" },
    ["b_ninja2"]  = { "file",          "ninja.lua" },
    ["b_oni1"]    = { "file",            "oni.lua" },
    ["b_oni2"]    = { "file",            "oni.lua" }
  },
  init = function(stage, world, char)
    setupFactions(char, {
      ninja = {"b_captain", "b_ninja1", "b_ninja2"},
      oni   = {"b_oni1", "b_oni2"}
    })

    world:placeCharacter("b_captain", 4, 6, "NW")
    world:placeCharacter( "b_ninja1", 3, 5, "NW")
    world:placeCharacter( "b_ninja2", 5, 5, "NW")
    world:placeCharacter(   "b_oni1", 3, 2, "SE")
    world:placeCharacter(   "b_oni2", 4, 2, "SE")

    char["b_captain"].agent:pushGoal("defeat-all-enemies")
  end
}

local stage2A =
{
  map = "map0.lua",
  rules = "r0",
  characters = {
    ["a_captain"] = { "file", "captain-brave.lua" },
    ["a_ninja1"]  = { "file",         "ninja.lua" },
    ["a_ninja2"]  = { "file",         "ninja.lua" },
    ["a_oni1"]    = { "file",           "oni.lua" },
    ["a_oni2"]    = { "file",           "oni.lua" },
    ["a_oni3"]    = { "file",           "oni.lua" },
    ["a_oni4"]    = { "file",           "oni.lua" }
  },
  init = function(stage, world, char)
    setupFactions(char, {
      ninja = {"a_captain", "a_ninja1", "a_ninja2"},
      oni   = {"a_oni1", "a_oni2", "a_oni3", "a_oni4"}
    })

    world:placeCharacter("a_captain", 4, 6, "NW")
    world:placeCharacter( "a_ninja1", 3, 5, "NW")
    world:placeCharacter( "a_ninja2", 5, 5, "NW")
    world:placeCharacter(   "a_oni1", 3, 2, "SE")
    world:placeCharacter(   "a_oni2", 4, 2, "SE")
    world:placeCharacter(   "a_oni3", 5, 2, "SE")
    world:placeCharacter(   "a_oni4", 6, 2, "SE")

    char["a_captain"].agent:pushGoal("defeat-all-enemies")
  end
}

local stage2B =
{
  map = "map0.lua",
  rules = "r0",
  characters = {
    ["b_captain"] = { "file", "captain-coward.lua" },
    ["b_ninja1"]  = { "file",          "ninja.lua" },
    ["b_ninja2"]  = { "file",          "ninja.lua" },
    ["b_oni1"]    = { "file",            "oni.lua" },
    ["b_oni2"]    = { "file",            "oni.lua" },
    ["b_oni3"]    = { "file",            "oni.lua" },
    ["b_oni4"]    = { "file",            "oni.lua" }
  },

  init = function(stage, world, char)
    setupFactions(char, {
    ninja = {"b_captain", "b_ninja1", "b_ninja2"},
    oni   = {"b_oni1", "b_oni2", "b_oni3", "b_oni4"}
    })

    world:placeCharacter("b_captain", 4, 6, "NW")
    world:placeCharacter( "b_ninja1", 3, 5, "NW")
    world:placeCharacter( "b_ninja2", 5, 5, "NW")
    world:placeCharacter(   "b_oni1", 3, 2, "SE")
    world:placeCharacter(   "b_oni2", 4, 2, "SE")
    world:placeCharacter(   "b_oni3", 5, 2, "SE")
    world:placeCharacter(   "b_oni4", 6, 2, "SE")

    char["b_captain"].agent:pushGoal("defeat-all-enemies")
  end
}

return
{
  name = {
    en = "Scenario 3",
    ja = "シナリオ３",
    it = "Scenario 3"
  },
  description = {
    en = [[
      Characters: Captain, Ninja, Oni

      Phases: 2

      Questions: Q5, Q6, Q7, Q8
    ]],
    ja = [[
      登場人物：　隊長、忍者、鬼

      フェーズ数：　２

      アンケート：　Q5、Q6、Q7、Q8
    ]],
    it = [[
      Personaggi: Capitano, Ninja, Oni

      Fasi: 2

      Domande: Q5, Q6, Q7, Q8
    ]],
  },
  phases =
  { -- Phase 1
    { "message",
      title = {
        en = "Phase 1",
        ja = "第一フェーズ",
        it = "Fase 1"
      },
      message = {
        en = [[The group faces 2 oni.]],
        ja = [[グループが鬼二匹に直面する。]],
        it = [[Il gruppo affronta 2 oni.]]
      }
    },
    { "battle",
      title = {
        en = "Phase 1",
        ja = "第一フェーズ",
        it = "Fase 1"
      },
      description = {
        en = "The group faces 2 oni.",
        ja = "グループが鬼二匹に直面する。",
        it = "Il gruppo affronta 2 oni."
      },
      stages = { stage1A, stage1B }
    },
    { "message",
      title = {
        en = "Phase 2",
        ja = "第二フェーズ",
        it = "Fase 2"
      },
      message = {
        en = [[The group faces 4 oni.]],
        ja = [[グループが鬼四匹に直面する。]],
        it = [[Il gruppo affronta 4 oni.]]
      }
    },
    { "battle",
      title = {
        en = "Phase 2",
        ja = "第二フェーズ",
        it = "Fase 2"
      },
      description = {
        en = "The group faces 4 oni.",
        ja = "グループが鬼四匹に直面する。",
        it = "Il gruppo affronta 4 oni."
      },
      stages = { stage2A, stage2B }
    }
  }
}
