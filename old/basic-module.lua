local Belief, Plan, Goal, Trigger = ys.bdi.Belief, ys.bdi.Plan, ys.bdi.Goal, ys.mas.Trigger
local m = ys.mas.Module("basic module")

m:add(Belief.External("position"))
m:add(Belief.External("view_range"))
m:add(Belief.External("hp"))
m:add(Belief.External("ap"))

m:add(
  Goal.define("be_in_location", {
    retry = false,
    on = {
      failure = function(goal, agent)
        log.d("goal failed")
      end,
      success = function(goal, agent)
        log.d("goal succeeded")
      end
    }}
  )
)

m:add(
  Plan.define("walk",
    function(agent, plan, parameters, beliefs, out)
      local dest = {x = parameters.x, y = parameters.y}
      local pos = beliefs.position
      local steps = 0

      while(dest.x ~= pos.x or dest.y ~= pos.y) do
        local dx, dy = 0, 0
        
        if pos.x < dest.x then dx =  1 end
        if pos.x > dest.x then dx = -1 end
        if pos.y < dest.y then dy =  1 end
        if pos.y > dest.y then dy = -1 end
        
        if beliefs.ap >= 10 then
          plan:waitForActuator(out.movement.legs.step(dx, dy))
          steps = steps + 1
        else
          plan:waitForEvent("turn_start") -- sbagliato!
        end
      end
      
      return steps
    end, {
    trigger = Trigger.Goal("be_in_location"),
    on = {
      failure = function(plan, agent)
      end,
      success = function(plan, agent)
      end
    }}
  )
)

return m