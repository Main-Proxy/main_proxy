# MasterProxy

Route requests to other Phoenix Endpoints or Plugs with WebSocket support.

> This library is useful for Gigalixir, Render or Heroku deployment when only one web port is exposed.

## Installation

Add `master_proxy` to your list of dependencies in `mix.exs`.

> If you are running an umbrella project, adding `master_proxy` as a dependency at the root `mix.exs` won't work. Instead, either add it to one of your child apps or create a new child app solely for the proxy.

```elixir
def deps do
  [
    {:master_proxy, "~> 0.1"}
  ]
end
```

Configure rules for routing requests by adding something like this in `config.exs`.

```elixir
config :master_proxy,
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

See [Configuration Examples](#configuration-examples) for more.

To avoid the platform routing requests directly to your Web apps' Endpoints, and thus bypassing the Endpoint on which MasterProxy is running, you can configure your other Web apps' Endpoints to not start a server in your production config.

```elixir
# An Endpoint on which MasterProxy is not running
config :my_app_web, MyAppWeb.Endpoint,
  # ...
  server: false
```

## Available Options

- `:http` - the configuration for the HTTP server. It accepts all options as defined by [Plug.Cowboy](https://hexdocs.pm/plug_cowboy/).
- `:https` - the configuration for the HTTPS server. It accepts all options as defined by [Plug.Cowboy](https://hexdocs.pm/plug_cowboy/).
- `:server` - `true` by default. If you are running application with `mix phx.server`, this option is ignored, and the server will always be started.
- `:backends` - the rule for routing requests. See [Configuration Examples](#configuration-examples) for more.
  - `:verb`
  - `:host`
  - `:path`
  - `:phoenix_endpoint` / `:plug`
  - `:opts` - only for `:plug`
- `:log_requests` - `true` by default. Log the requests or not.

## Configuration Examples

### Route requests to apps based on hostname

```elixir
config :master_proxy,
  http: [port: 80],
  backends: [
    %{
      host: ~r{^app-name\.gigalixirapp\.com$},
      phoenix_endpoint: MyAppWeb.Endpoint
    },
    %{
      host: ~r{^www\.example\.com$},
      phoenix_endpoint: MyAppWeb.Endpoint
    },
    %{
      host: ~r{^api\.example\.com$},
      phoenix_endpoint: MyAppApiWeb.Endpoint
    },
    %{
      host: ~r{^members\.example\.com$},
      phoenix_endpoint: MyAppMembersWeb.Endpoint
    }
  ]
```

## How does it work?

1. We start a Cowboy server with a single dispatch handler: `MasterProxy.Cowboy2Handler`.
2. The handler checks the verb, host and path of the request, and compares them to the supplied configuration to determine where to route the request.
3. If the backend that matched is a Phoenix Endpoint, MasterProxy delegates to the `Phoenix.Endpoint.Cowboy2Handler` with your app's Endpoint.
4. If the backend that matched is a plug, MasterProxy simply calls the plug as normal.
5. If no backend is matched, a text response with a status code of 404 is returned.

## Development

```bash
mix run --no-halt
curl -i foo.com.127.0.0.1.xip.io:4080
curl -i localhost:4080
```

## Thanks

This application is based on the [master_proxy](https://github.com/wojtekmach/acme_bank/tree/master/apps/master_proxy) application inside the [acme_bank](https://github.com/wojtekmach/acme_bank) project, which was based on a gist shared by [Gazler](https://github.com/Gazler).
