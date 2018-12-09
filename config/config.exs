use Mix.Config

# config :logger, level: :info

config :master_proxy, 
  http: [:inet6, port: System.get_env("PORT") || 4000],
  backends: [
    # %{
    #   path: ~r(phoenix/live_reload/socket),
    #   socket: Phoenix.LiveReloader.Socket
    # },
    %{
      verb: ~r/GET/i,
      host: ~r/foo.com.127.0.0.1.xip.io/,
      path: ~r/\/.*/,
      # allow one_of phoenix_endpoint, plug, or socket?
      phoenix_endpoint: MasterProxy.Plug.Test
    }
  ]
