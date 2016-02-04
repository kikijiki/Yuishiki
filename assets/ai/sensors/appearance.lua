return {
  triggers = {
    {
      event = {"character", "new"},
      body = function(self, source, event)
        if self.character == class then return end
        self.belief_base.setLT(source.status.race:get(),  "characters", source.id,  "status.race")
        self.belief_base.setLT(source.status.class:get(), "characters", source.id, "status.class")
      end
    }
  }
}
