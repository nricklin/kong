local json = require "cjson"
local http_client = require "kong.tools.http_client"
local spec_helper = require "spec.spec_helpers"
local utils = require "kong.tools.utils"

describe("Admin API", function()

  setup(function()
    spec_helper.start_kong()
  end)

  teardown(function()
    spec_helper.stop_kong()
  end)

  describe("/cluster/", function()
    local BASE_URL = spec_helper.API_URL.."/cluster/"

    describe("GET", function()

      it("[SUCCESS] should get the list of members", function()
        local response, status = http_client.get(BASE_URL, {}, {})
        assert.equal(200, status)
        local body = json.decode(response)
        assert.truthy(body)
        assert.equal(1, #body)

        local member = table.remove(body, 1)
        assert.equal(4, utils.table_size(member))
        assert.truthy(member.addr)
        assert.truthy(member.status)
        assert.truthy(member.name)
        assert.truthy(member.port)
        
        assert.equal("alive", member.status)
      end)

    end)

  end)

  describe("/cluster/events/", function()
    local BASE_URL = spec_helper.API_URL.."/cluster/events"

    describe("POST", function()

      it("[SUCCESS] should post a new event", function()
        local _, status = http_client.post(BASE_URL, {}, {})
        assert.equal(200, status)
      end)

    end)

  end)
end)