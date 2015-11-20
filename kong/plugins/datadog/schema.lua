local ALLOWED_LEVELS = { "debug", "info", "notice", "warning", "err", "crit", "alert", "emerg" }

return {
  fields = {
    host = { type = "string", default = "logs-01.loggly.com" },
    port = { type = "number", default = 514 },
    key = { required = true, type = "string"},
    namespace = { type = "string", default = "kong" }
  }
}
