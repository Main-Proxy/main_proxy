import Config

config :master_proxy,
  http: [:inet6, port: System.get_env("PORT") || 4000],
  backends: [
    %{
      verb: ~r/GET/i,
      host: ~r/foo.com.127.0.0.1.xip.io/,
      path: ~r/\/.*/,
      phoenix_endpoint: MasterProxy.Plug.Test
    }
  ]
