local setmetatable = setmetatable

local function create_statsd_message(conf, message, pri)
  local message = {
    
  }
  
end

local stasd_mt = {}
function _M:new(conf)
  local stasd = {
    host = conf.host,
    port = conf.port,
    namespace = conf.namespace
  }
  return setmetatable(stasd, stasd_mt)
end

function _M:gauge(value, sample_rate)
  return create_statsd_message(value, "g", sample_rate)
end

function _M:counter(value, sample_rate, ...)
  return create_statsd_message(value, "c", sample_rate, ...)
end

function _M:counter(stat, value, sample_rate)
  return counter_(stat, value, sample_rate)
end

function _M:increment(stat, value, sample_rate)
  return counter_(stat, value or 1, sample_rate, false)
end

function _M:decrement(stat, value, sample_rate)
  value = value or 1
  if type(stat) == 'string' then value = -value end
  return counter_(value, sample_rate, true)
end

function _M:timer(stat, ms)
  return create_statsd_message(stat, ms, "ms")
end

function _M:histogram(stat, value)
  return create_statsd_message(stat, value, "h")
end

function _M:meter(stat, value)
  return create_statsd_message(stat, value, "m")
end

function set(stat, value)
  return create_statsd_message(stat, value, "s")
end

return _M
