local spec_helper = require "spec.spec_helpers"
local http_client = require "kong.tools.http_client"
local cjson = require "cjson"

local STUB_GET_URL = spec_helper.STUB_GET_URL
local STUB_POST_URL = spec_helper.STUB_POST_URL

describe("Request Transformer", function()

  setup(function()
    spec_helper.prepare_db()
    spec_helper.insert_fixtures {
      api = {
        { name = "tests-request-transformer-1", request_host = "test1.com", upstream_url = "http://mockbin.com" },
        { name = "tests-request-transformer-2", request_host = "test2.com", upstream_url = "http://httpbin.org" },
        { name = "tests-request-transformer-3", request_host = "test3.com", upstream_url = "http://mockbin.com" }
      },
      plugin = {
        {
          name = "request-transformer",
          config = {
            add = {
              headers = {"x-added:true", "x-added2:true" },
              querystring = {"newparam:value"},
              form = {"newformparam:newvalue"}
            },
            remove = {
              headers = { "x-to-remove" },
              querystring = { "toremovequery" },
              form = { "toremoveform" }
            }
          },
          __api = 1
        },
        {
          name = "request-transformer",
          config = {
            add = {
              headers = { "host:mark" }
            }
          },
          __api = 2
        },
        {
          name = "request-transformer",
          config = {
            add = {
              headers = {"x-added:a1", "x-added2:b1"},
              querystring = {"p1:a1"},
              form = {"newformparam:newvalue"}
            },
            remove = {
              headers = { "x-to-remove" },
              querystring = { "toremovequery" }
            },
            concat = {
              headers = {"x-added:a2", "x-added:a3"},
              querystring = {"p1:a2", "p2:b1"}
            }
          },
          __api = 3
        }
      },
    }

    spec_helper.start_kong()
  end)

  teardown(function()
    spec_helper.stop_kong()
  end)

  describe("Test adding parameters", function()
    
    it("should add new headers", function()
      local response, status = http_client.get(STUB_GET_URL, {}, {host = "test1.com"})
      local body = cjson.decode(response)
      assert.are.equal(200, status)
      assert.are.equal("true", body.headers["x-added"])
      assert.are.equal("true", body.headers["x-added2"])
    end)

    it("should add new parameters on POST", function()
      local response, status = http_client.post(STUB_POST_URL, {}, {host = "test1.com"})
      local body = cjson.decode(response)
      assert.are.equal(200, status)
      assert.are.equal("newvalue", body.postData.params["newformparam"])
    end)

    it("should add new parameters on POST when existing params exist", function()
      local response, status = http_client.post(STUB_POST_URL, { hello = "world" }, {host = "test1.com"})
      local body = cjson.decode(response)
      assert.are.equal(200, status)
      assert.are.equal("world", body.postData.params["hello"])
      assert.are.equal("newvalue", body.postData.params["newformparam"])
    end)

    it("should add new parameters on multipart POST", function()
      local response, status = http_client.post_multipart(STUB_POST_URL, {}, {host = "test1.com"})
      local body = cjson.decode(response)
      assert.are.equal(200, status)
      assert.are.equal("newvalue", body.postData.params["newformparam"])
    end)

    it("should add new parameters on multipart POST when existing params exist", function()
      local response, status = http_client.post_multipart(STUB_POST_URL, { hello = "world" }, {host = "test1.com"})
      local body = cjson.decode(response)
      assert.are.equal(200, status)
      assert.are.equal("world", body.postData.params["hello"])
      assert.are.equal("newvalue", body.postData.params["newformparam"])
    end)

    it("should add new parameters on GET", function()
      local response, status = http_client.get(STUB_GET_URL, {}, {host = "test1.com"})
      local body = cjson.decode(response)
      assert.are.equal(200, status)
      assert.are.equal("value", body.queryString["newparam"])
    end)
    
    it("should change the host header", function()
      local response, status = http_client.get(spec_helper.PROXY_URL.."/get", {}, {host = "test2.com"})
      local body = cjson.decode(response)
      assert.are.equal(200, status)
      assert.are.equal("mark", body.headers["Host"])
    end)

  end)

  describe("Test removing parameters", function()

    it("should remove a header", function()
      local response, status = http_client.get(STUB_GET_URL, {}, {host = "test1.com", ["x-to-remove"] = "true"})
      local body = cjson.decode(response)
      assert.are.equal(200, status)
      assert.falsy(body.headers["x-to-remove"])
    end)

    it("should remove parameters on POST", function()
      local response, status = http_client.post(STUB_POST_URL, {["toremoveform"] = "yes", ["nottoremove"] = "yes"}, {host = "test1.com"})
      local body = cjson.decode(response)
      assert.are.equal(200, status)
      assert.falsy(body.postData.params["toremoveform"])
      assert.are.same("yes", body.postData.params["nottoremove"])
    end)

    it("should remove parameters on multipart POST", function()
      local response, status = http_client.post_multipart(STUB_POST_URL, {["toremoveform"] = "yes", ["nottoremove"] = "yes"}, {host = "test1.com"})
      local body = cjson.decode(response)
      assert.are.equal(200, status)
      assert.falsy(body.postData.params["toremoveform"])
      assert.are.same("yes", body.postData.params["nottoremove"])
    end)

    it("should remove parameters on GET", function()
      local response, status = http_client.get(STUB_GET_URL, {["toremovequery"] = "yes", ["nottoremove"] = "yes"}, {host = "test1.com"})
      local body = cjson.decode(response)
      assert.are.equal(200, status)
      assert.falsy(body.queryString["toremovequery"])
      assert.are.equal("yes", body.queryString["nottoremove"])
    end)

  end)
  
   describe("Test concatenating parameters", function()
    
    it("should add new header if missing", function()
      local response, status = http_client.get(STUB_GET_URL, {}, {host = "test3.com"})
      local body = cjson.decode(response)
      assert.are.equal(200, status)
      assert.are.equal("b1", body.headers["x-added2"])
    end)
    
    it("should concatenate values to existing headers", function()
      local response, status = http_client.get(STUB_GET_URL, {}, {host = "test3.com"})
      local body = cjson.decode(response)
      assert.are.equal(200, status)
      assert.are.equal("a1, a2, a3", body.headers["x-added"])
    end)
    
    it("should add new parameters on POST when query string key missing", function()
      local response, status = http_client.post(STUB_POST_URL, { hello = "world" }, {host = "test3.com"})
      local body = cjson.decode(response)
      assert.are.equal(200, status)
      assert.are.equal("b1", body.queryString["p2"])
    end)
    
    it("should concat value on POST when query string key exists", function()
      local response, status = http_client.post(STUB_POST_URL.."/?q1=20", { hello = "world" }, {host = "test3.com"})
      local body = cjson.decode(response)
      assert.are.equal(200, status)
      assert.are.equal("a1", body.queryString["p1"][1])
      assert.are.equal("a2", body.queryString["p1"][2])
      assert.are.equal("20", body.queryString["q1"])
    end)
  end)
end)
