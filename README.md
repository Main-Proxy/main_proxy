# MainProxy

<!-- MDOC !-->

Route requests to other Phoenix Endpoints or Plugs with WebSocket support.

> This library is useful for Gigalixir, Render, Heroku or other deployments where only one web port is exposed.

## Installation

Add MainProxy to your list of dependencies in `mix.exs`.

> If you are running an umbrella project, adding MainProxy as a dependency at the root `mix.exs` won't work. Instead, either add it to one of your child apps or create a new child app solely for the proxy.

```elixir
def deps do
  [
    {:main_proxy, "~> 0.1"},
  ]
end
```

## Usage

Configure listening options for MainProxy:

```elixir
config :main_proxy,
  http: [port: 4080],
  https: [port: 4443]
```

Create a proxy module which configures backends:

```elixir
defmodule MyApp.Proxy do
  use MainProxy.Proxy

  @impl MainProxy.Proxy
  def backends do
    [
      %{
        domain: "my-cool-app.com",
        phoenix_endpoint: MyAppWeb.Endpoint
      },
      %{
        domain: "members.my-cool-app.com",
        phoenix_endpoint: MyAppMembersWeb.Endpoint
      },
      %{
        verb: ~r/get/i,
        path: ~r{^/main-proxy-plug-test$},
        plug: MainProxy.Plug.Test,
        opts: [1, 2, 3]
      }
    ]
  end
end
```

> Backends can also be configured via configuration:
>
> ```elixir
> config :main_proxy,
>   backends: [
>     # ...
>   ]
> ```
>
> But, it's not the recommended way.

Add above created proxy module to the supervision tree:

```elixir
children = [
  # ... other children
  MyApp.Proxy,
]
```

Configure all endpoints to not start a server in order to avoid endpoints bypassing MainProxy:

```elixir
# ...
config :my_app, MyAppWeb.Endpoint, server: false
config :my_app_members, MyAppMembersWeb.Endpoint, server: false
```

## Available Configuration Options

- `:http` - the configuration for the HTTP server. It accepts all options as defined by [Plug.Cowboy](https://hexdocs.pm/plug_cowboy/).
- `:https` - the configuration for the HTTPS server. It accepts all options as defined by [Plug.Cowboy](https://hexdocs.pm/plug_cowboy/).
- `:server` - `true` by default. If you are running application with `mix phx.server`, this option is ignored, and the server will always be started.
- `:backends` - the rule for routing requests. See [Configuration Examples](#configuration-examples) for more.
  - `:domain`
  - `:verb`
  - `:host`
  - `:path`
  - `:phoenix_endpoint` / `:plug`
  - `:opts` - only for `:plug`
- `:log_requests` - `true` by default. Log the requests or not.

## Configuration Examples

### Route requests to apps based on hostname

```elixir
defmodule MyApp.Proxy do
  use MainProxy.Proxy

  @impl MainProxy.Proxy
  def backends do
    [
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
  end
end
```

### Configuration via application config

```elixir
config :main_proxy,
  http: [port: 80],
  backends: [
    %{
      host: ~r{^app-name\.gigalixirapp\.com$},
      phoenix_endpoint: MyAppWeb.Endpoint
    },
    %{
      host: ~r{^www\.example\.com$},
      phoenix_endpoint: MyAppWeb.Endpoint
    }
  ]
```

<!-- MDOC !-->

## How does MainProxy work?

1. We start a Cowboy server with a single dispatch handler: `MainProxy.Cowboy2Handler`.
2. The handler checks the verb, host and path of the request, and compares them to the supplied configuration to determine where to route the request.
3. If the backend that matched is a `phoenix_endpoint`, MainProxy delegates to the `Phoenix.Endpoint.Cowboy2Handler` with your app's Endpoint.
4. If the backend that matched is a `plug`, MainProxy calls the plug as normal.
5. If no backend is matched, a text response with a status code of 404 is returned.

## Development

```bash
mix run --no-halt
curl -i foo.com.127.0.0.1.xip.io:4080
curl -i localhost:4080
```

## Thanks

This application is based on the [main_proxy](https://github.com/wojtekmach/acme_bank/tree/master/apps/main_proxy) application inside the [acme_bank](https://github.com/wojtekmach/acme_bank) project, which was based on a gist shared by [Gazler](https://github.com/Gazler).
