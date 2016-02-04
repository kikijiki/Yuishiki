return {
  triggers = {
    {
      event = {"character", "value", "status", "hp"},
      body = function(self, source, event, hp, new, old)
        local maxhp = source.status.maxhp:get()
        local health = new / maxhp
        self.belief_base.setST(health, "characters", source.id, "status.health")
      end
    },
    {
      event = {"character", "value", "status", "alive"},
      body = function(self, source, event, alive, new, old)
        local alive = source.status.alive:get()
        self.belief_base.setLT(alive, "characters", source.id, "alive")
      end
    }
  },

  update = function(self, world)
    for _,c in world:otherCharacterPairs(self.character) do
      local hp = c.status.hp:get()
      local maxhp = c.status.maxhp:get()
      local health = hp / maxhp
      local alive = c.status.alive:get()
      self.belief_base.setST(health, "characters", c.id, "status.health")
      self.belief_base.setLT(alive, "characters", c.id, "alive")
    end
  end
}
