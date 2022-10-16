# MainProxy

<!-- MDOC !-->

Route requests to other Phoenix Endpoints or Plugs with WebSocket support.

> This library is useful for Gigalixir, Render, Heroku or other deployments where only one web port is exposed.

## Installation

Add MainProxy to your list of dependencies in `mix.exs`.

Note: if you are running an umbrella project, adding MainProxy as a dependency at the root `mix.exs` won't work. Instead, either add it to one of your child apps or create a new child app solely for the proxy.

```elixir
def deps do
  [
    {:main_proxy, "~> 0.1"},
  ]
end
```

Configure rules for routing requests by adding configuration (i.e.
`config/config.exs`). Backend configuration is optional and can be replaced by
the `merge_config/2` callback of your proxy module (more info below) if you need
to generate configuration at runtime.

```elixir
config :main_proxy,
  # any Cowboy options are allowed
  http: [:inet6, port: 4080],
  https: [:inet6, port: 4443]
```

Note: backends can also be configured via configuration, but configuring the
backends via your proxy module (see the `use MainProxy.Proxy` example below)
is recommended.

See [Configuration Examples](#module-configuration-examples) for more.

Then create the proxy module and add it to your application startup (often in `MyApp.Application`):

module:
``` elixir
defmodule MyApp.Proxy do
  use MainProxy.Proxy

  @impl MainProxy.Proxy
  def backends do
    [
      %{
        domain: "my-cool-app.com",
        phoenix_endpoint: MyCoolAppWeb.Endpoint
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

Proxies must be explicitly started as part of your application supervision tree.
Proxies can be added to the supervision tree as follows (usually in `MyApp.Application`):

    children = [
      # ... other children
      MyApp.Proxy,
    ]

To avoid the platform routing requests directly to your Web apps' Endpoints, and thus bypassing the Endpoint on which MainProxy is running, you can configure your other Web apps' Endpoints to not start a server in your production config.

```elixir
# An Endpoint on which MainProxy is not running
config :my_app_web, MyAppWeb.Endpoint,
  # ...
  server: false
```

## Available Options

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

<a id="module-configuration-examples"></a>
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

``` elixir
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
