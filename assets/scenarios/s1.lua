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
    ["hikoichi"] = { "file", "hikoichi.lua" },
    [     "oni"] = { "file",      "oni.lua" }
  },
  init = function(stage, world, char)
    world:placeCharacter("hikoichi", 4, 4, "NW")
    world:placeCharacter(     "oni", 4, 2, "SE")

    setupFactions(char, {
      ninja = {"hikoichi"},
      oni   = {"oni"}
    })
  end
}

local stage2 =
{
  map = "map0.lua",
  rules = "r0",
  characters = {
    ["hikoichi"] = { "file", "hikoichi.lua" },
    ["hikomaru"] = { "file", "hikomaru.lua" },
    [    "oni1"] = { "file",      "oni.lua" },
    [    "oni2"] = { "file",      "oni.lua" },
  },
  init = function(stage, world, char)
    world:placeCharacter("hikoichi", 2, 7, "NW")
    world:placeCharacter("hikomaru", 7, 5, "NW")
    world:placeCharacter(    "oni1", 2, 5, "SE")
    world:placeCharacter(    "oni2", 7, 3, "SE")

    setupFactions(char, {
      ninja = {"hikoichi", "hikomaru"},
      oni   = {"oni1", "oni2"}
    })

    char["hikoichi"].agent:setBeliefLT(true, "no-cooperation")
    char["hikomaru"].agent:setBeliefLT(true, "no-cooperation")
  end
}

return
{
  name = {
    en = "Scenario 1",
    ja = "シナリオ１",
    it = "Scenario 1"
  },
  description = {
    en = [[
      Characters: Hikoichi, Hikomaru, Oni

      Phases: 2

      Questions: Q1, Q2
    ]],

    ja = [[
      登場人物：　ヒコイチ、ヒコマル、鬼

      フェーズ数：　２

      アンケート：　Q1、　Q2
    ]],

    it = [[
      Personaggi: Hikoichi, Hikomaru, Oni

      Fasi: 2

      Domande: Q1, Q2
    ]]
  },
  phases =
  {
    { "message",
      title = {
        en = "First phase",
        ja = "第一フェーズ",
        it = "Prima fase"
      },
      message = {
        en = [[Hikoichi fights against an oni for the first time.]],
        ja = [[キヒコイチが初めて鬼と戦う。]],
        it = [[Hikoichi combatte contro un oni per la prima volta]]
      }
    },
    { "battle",
      title = {
        en = "First phase",
        ja = "第一フェーズ",
        it = "Prima fase"
      },
      description = {
        en = "Hikoichi fights against an oni for the first time.",
        ja = "キヒコイチが初めて鬼と戦う。",
        it = "Hikoichi combatte contro un oni per la prima volta"
      },
      stages = { stage1 }
    },
    { "message",
      title = {
        en = "Second phase",
        ja = "第二フェーズ",
        it = "Seconda fase"
      },
      message = {
        en = [[Hikoichi fights again against an oni. Hikomaru joins too. ]],
        ja = [[ヒコイチがもう一回鬼と戦う。ヒコマルも参加する。]],
        it = [[Hikoichi combatte di nuovo contro un oni. Hikomaru si unisce alla battaglia.]]
      }
    },
    { "battle",
      title = {
        en = "Second phase",
        ja = "第二フェーズ",
        it = "Seconda fase"
      },
      description = {
        en = "Hikoichi fights again against an oni. Hikomaru joins too.",
        ja = "ヒコイチがもう一回鬼と戦う。ヒコマルも参加する。",
        it = "Hikoichi combatte di nuovo contro un oni. Hikomaru si unisce alla battaglia."
      },
      stages = { stage2 }
    }
  }
}
