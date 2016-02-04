return {
  triggers = {
    {
      event = {"character", "value", "status", "position"},
      body = function(self, source, event, position, new, old)
        self.belief_base.setST(new, "characters", source.id, "status.position")
      end
    },
    {
      event = {"character", "removed"},
      body = function(self, source, event)
        self.belief_base.setST(nil, "characters", source.id, "status.position")
      end
    }
  },

  update = function(self, world)
    for _,c in world:otherCharacterPairs(self.character) do
      self.belief_base.setST(
        c.status.position:get(), "characters", c.id, "status.position")
    end
  end
}
