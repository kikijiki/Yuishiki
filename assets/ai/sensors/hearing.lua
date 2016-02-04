return {
  triggers = {
    {
      event = {"character", "speech"},
      body = function(self, source, event, message)
        if message.performative then
          self.agent:sendEvent("message", message)
        end
      end
    }
  }
}
