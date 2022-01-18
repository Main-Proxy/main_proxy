import Config

config :master_proxy,
  conn: Plug.Cowboy.Conn

config :master_proxy, MasterProxy.Test.Endpoint,
  http: [port: 4002],
  url: [host: "localhost"],
  secret_key_base: "R832e8CbBikpA2VT50k07PRjmPu9PbDM6ZbNi44s/zVxSSmK1m7H+7Tew4vPwOGX",
  server: false

config :phoenix, :json_library, Jason

config :master_proxy,
  http: [:inet6, port: 5907]

config :logger, level: :warn
