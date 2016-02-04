return {
  triggers = {
    {
      event = {"character", "value", "status", "alive"},
      body = function(self, source, event, alive, new, old)
        if alive then return end
        local belief_name = "enemy-count"

        if source.status.faction:get() == self.character.status.faction:get() then
          belief_name = "ally-count" end

        local count = self.belief_base.get(belief_name)
        count = math.max(0, count - 1)
        self.belief_base.setST(count, belief_name)
      end
    }
  },
  update = function(self, world)
    local enemies = 0
    local allies = 0
    local characters = self.belief_base.d.characters
    if not characters then return end
    for id,c in pairs(characters) do
      if id ~= self.character.id and world.characters[id] then
        if c.faction:get() == "ally" then allies = allies + 1
        else enemies = enemies + 1 end
      end
    end
    self.belief_base.setST(allies, "ally-count")
    self.belief_base.setST(enemies, "enemy-count")
  end
}
