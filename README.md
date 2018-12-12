# MasterProxy

Proxies requests to Web apps that are part of the platform. Useful for Gigalixir or Heroku deployment when just one web port is exposed.

Works with phoenix endpoints, plugs, and websockets.

This application is based on the [master_proxy](https://github.com/wojtekmach/acme_bank/tree/master/apps/master_proxy) application inside the [acme_bank](https://github.com/wojtekmach/acme_bank) project, which was based on a gist shared by @Gazler.

## Installation

Add `master_proxy` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:master_proxy, "~> 0.1.0"}
  ]
end
```

Configure how master_proxy should route requests by adding something like this in `config.exs`.

```elixir
config :master_proxy, 
  # any cowboy options are allowed 
  http: [:inet6, port: 4080],
  https: [:inet6, port: 4443],
  backends: [
    %{
      host: ~r/localhost/,
      phoenix_endpoint: MyAppWeb.Endpoint
    },
    %{
      verb: ~r/get/i,
      path: ~r{^/master-proxy-plug-test$},
      plug: MasterProxy.Plug.Test,
      opts: [1, 2, 3]
    }
  ]
```

## How does this work?

1. We start a cowboy server with a single dispatch handler: MasterProxy.Cowboy2Handler
2. The handler looks at the verb, host, and path and compares it to the configuration you supplied to decide where to route the request
  a. If the backend that matched is a `phoenix_endpoint` it delegates to the Phoenix.Endpoint.Cowboy2Handler with your app's `Endpoint`
  b. If the backend that matched is a `plug`, then it just calls the plug as normal

## Development

```bash
mix run --no-halt
curl -i foo.com.127.0.0.1.xip.io:3333 # matches host
curl -i localhost:3333 # not found case
```
