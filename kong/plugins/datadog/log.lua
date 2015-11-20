local lsyslog = require "lsyslog"
local cjson = require "cjson"
local statsd = require "statsd"

local ngx_log = ngx.log
local ngx_timer_at = ngx.timer.at
local ngx_socket_udp = ngx.socket.udp


local _M = {}

local function create_statsd_message(conf, message, pri)
  
end

local function log(conf, message, pri)
  local host = conf.host
  local port = conf.port
  local timeout = conf.timeout
  local statsd_message = create_statsd_message(conf, message, pri)
  local sock = ngx_socket_udp()
  sock:settimeout(timeout)

  local ok, err = sock:setpeername(host, port)
  if not ok then
    ngx_log(ngx.ERR, "failed to connect to "..host..":"..tostring(port)..": ", err)
    return
  end
  local ok, err = sock:send(udp_message)
  if not ok then
    ngx_log(ngx.ERR, "failed to send data to ".. host..":"..tostring(port)..": ", err)
  end

  local ok, err = sock:close()
  if not ok then
    ngx_log(ngx.ERR, "failed to close connection from "..host..":"..tostring(port)..": ", err)
    return
  end
end

function _M.execute(conf, message)
  local ok, err = ngx_timer_at(0, log, conf, message)
  if not ok then
    ngx_log(ngx.ERR, "failed to create timer: ", err)
  end
end

return _M
