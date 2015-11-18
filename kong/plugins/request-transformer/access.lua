local utils = require "kong.tools.utils"
local stringy = require "stringy"
local multipart = require "multipart"

local table_insert = table.insert
local req_set_uri_args = ngx.req.set_uri_args
local req_get_uri_args = ngx.req.get_uri_args
local req_set_header = ngx.req.set_header
local req_get_headers = ngx.req.get_headers
local req_read_body = ngx.req.read_body
local req_set_body_data = ngx.req.set_body_data
local req_get_body_data = ngx.req.get_body_data
local req_clear_header = ngx.req.clear_header
local req_get_post_args = ngx.req.get_post_args
local encode_args = ngx.encode_args
local type = type
local string_len = string.len

local _M = {}

local CONTENT_LENGTH = "content-length"
local FORM_URLENCODED = "application/x-www-form-urlencoded"
local MULTIPART_DATA = "multipart/form-data"
local CONTENT_TYPE = "content-type"
local HOST = "host"

local function iterate_and_exec(val, cb)
  if utils.table_size(val) > 0 then
    for _, entry in ipairs(val) do
      local parts = stringy.split(entry, ":")
      cb(parts[1], utils.table_size(parts) == 2 and parts[2] or nil)
    end
  end
end

local function get_content_type()
  local header_value = req_get_headers()[CONTENT_TYPE]
  if header_value then
    return stringy.strip(header_value):lower()
  end
end

local function concat_value(current_value, value)
  local current_value_type = type(current_value)
 
  if current_value_type  == "string" then
    return { current_value, value }
  elseif current_value_type  == "table" then
    table_insert(current_value, value)
    return current_value  
  else
    return { value } 
  end
end

function _M.execute(conf)
  if conf.add then

    -- Add headers
    if conf.add.headers then
      iterate_and_exec(conf.add.headers, function(name, value)
        req_set_header(name, value)
        if name:lower() == HOST then -- Host header has a special treatment
          ngx.var.backend_host = value
        end
      end)
    end

    -- Add Querystring
    if conf.add.querystring then
      local querystring = req_get_uri_args()
      iterate_and_exec(conf.add.querystring, function(name, value)
        querystring[name] = value
      end)
      req_set_uri_args(querystring)
    end

    if conf.add.form then
      local content_type = get_content_type()
      if content_type and stringy.startswith(content_type, FORM_URLENCODED) then
        -- Call req_read_body to read the request body first
        req_read_body()

        local parameters = req_get_post_args()
        iterate_and_exec(conf.add.form, function(name, value)
          parameters[name] = value
        end)
        local encoded_args = encode_args(parameters)
        req_set_header(CONTENT_LENGTH, string_len(encoded_args))
        req_set_body_data(encoded_args)
      elseif content_type and stringy.startswith(content_type, MULTIPART_DATA) then
        -- Call req_read_body to read the request body first
        req_read_body()

        local body = req_get_body_data()
        local parameters = multipart(body and body or "", content_type)
        iterate_and_exec(conf.add.form, function(name, value)
          parameters:set_simple(name, value)
        end)
        local new_data = parameters:tostring()
        req_set_header(CONTENT_LENGTH, string_len(new_data))
        req_set_body_data(new_data)
      end
    end

  end

  if conf.remove then

    -- Remove headers
    if conf.remove.headers then
      iterate_and_exec(conf.remove.headers, function(name, value)
        req_clear_header(name)
      end)
    end

    if conf.remove.querystring then
      local querystring = req_get_uri_args()
      iterate_and_exec(conf.remove.querystring, function(name)
        querystring[name] = nil
      end)
      req_set_uri_args(querystring)
    end

    if conf.remove.form then
      local content_type = get_content_type()
      if content_type and stringy.startswith(content_type, FORM_URLENCODED) then
        local parameters = req_get_post_args()

        iterate_and_exec(conf.remove.form, function(name)
          parameters[name] = nil
        end)

        local encoded_args = encode_args(parameters)
        req_set_header(CONTENT_LENGTH, string_len(encoded_args))
        req_set_body_data(encoded_args)
      elseif content_type and stringy.startswith(content_type, MULTIPART_DATA) then
        -- Call req_read_body to read the request body first
        req_read_body()

        local body = req_get_body_data()
        local parameters = multipart(body and body or "", content_type)
        iterate_and_exec(conf.remove.form, function(name)
          parameters:delete(name)
        end)
        local new_data = parameters:tostring()
        req_set_header(CONTENT_LENGTH, string_len(new_data))
        req_set_body_data(new_data)
      end
    end

  end
  
  if conf.concat then

    -- Concat headers
    if conf.concat.headers then
      iterate_and_exec(conf.concat.headers, function(name, value)
        req_set_header(name, concat_value(req_get_headers()[name], value))
        if name:lower() == HOST then -- Host header has a special treatment
          ngx.var.backend_host = value
        end
      end)
    end

    -- Concat Querystring
    if conf.concat.querystring then
      local querystring = req_get_uri_args()
      iterate_and_exec(conf.concat.querystring, function(name, value)
        querystring[name] = concat_value(querystring[name], value)
      end)
      req_set_uri_args(querystring)
    end
  end
end

return _M
