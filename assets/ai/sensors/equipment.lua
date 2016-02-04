return {
  triggers = {
    {
      event = {"character", "equipment"},
      body = function(self, source, event, slot, equipment, item, old)
        self.belief_base.setST(item, "characters", source.id, "equipment", slot)
      end
    }
  },

  update = function(self, world)
    for _,c in world:otherCharacterPairs(self.character) do
      for slot, item in c.equipment:pairs() do
        self.belief_base.setST(item, "characters", c.id, "equipment", slot)
      end
    end
  end
}
