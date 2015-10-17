local _M = {}

-- Services ordered by priority
local services = {
  require "kong.cli.services.serf",
  require "kong.cli.services.dnsmasq",
  require "kong.cli.services.nginx"
}

function _M.stop_all(configuration)
  -- Stop in reverse order to keep dependencies running
  for index = #services,1,-1 do
    services[index](configuration.value, configuration.path):stop()
  end
end

function _M.start_all(configuration)
  for _, v in ipairs(services) do
    local obj = v(configuration.value, configuration.path)
    obj:prepare()
    local ok, err = obj:start()
    if not ok then
      return ok, err
    end
  end

  return true
end

return _M