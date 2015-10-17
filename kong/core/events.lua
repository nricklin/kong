local Object = require "classic"
local Mediator = require "mediator"

local Events = Object:extend()

Events.TYPES = {
  CLUSTER_PROPAGATE = "CLUSTER_PROPAGATE",
  ENTITY_CREATED = "ENTITY_CREATED",
  ENTITY_UPDATED = "ENTITY_UPDATED",
  ENTITY_DELETED = "ENTITY_DELETED"
}

function Events:new(plugins)
  self._mediator = Mediator()
end

function Events:subscribe(event_name, fn)
  if fn then
    self._mediator:subscribe({event_name}, function(message_t)
      fn(message_t)
      return nil, true -- Required to tell mediator to continue processing other events
    end)
  end
end

function Events:publish(event_name, message_t)
  self._mediator:publish({event_name}, message_t)
end

return Events