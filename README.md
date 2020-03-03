# MasterProxy

Proxies requests to Web apps that are part of the platform. Useful for Gigalixir, Render or Heroku deployment when only one web port is exposed.

Works with Phoenix Endpoints, Plugs and WebSockets.

This application is based on the [master_proxy](https://github.com/wojtekmach/acme_bank/tree/master/apps/master_proxy) application inside the [acme_bank](https://github.com/wojtekmach/acme_bank) project, which was based on a gist shared by [Gazler](https://github.com/Gazler).

This particular fork reimagines the OTP app version into a supervisor pattern that allows runtime config to be passed in and overwrite the compile-time config, allowing for greater flexibility from deployment to deployment.

## Installation

Add `master_proxy` to your list of dependencies in `mix.exs`.

Note: if you are running an umbrella project, adding MasterProxy as a dependency at the root `mix.exs` won't work. Instead, either add it to one of your child apps or create a new child app solely for the proxy.

```elixir
def deps do
  [
    {:master_proxy, "~> 0.1"}
  ]
end
```

Configure how MasterProxy should route requests by adding something like this in `config.exs`.

```elixir
config :master_proxy, 
  # any Cowboy options are allowed
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

And then run as a child of your application, overriding any config you need for the environment:
```elixir
# with Supervisor.Spec imported

children = [
  supervisor(MasterProxy, [[http: port: 8040]]),
  supervisor(MyApp.Endpoint1, [])
  supervisor(MyApp.Endpoint2, [])
]

opts = [strategy: :one_for_one, name: MyApp.Supervisor]
Supervisor.start_link(children, opts)
```

(MasterProxy does not need to be a sibling of the `Endpoint`s you wish to delegate to, you could have a different app in your umbrella which depends on those apps that handles the `MasterProxy` process and providing runtime config)

For further configuration examples, see below.

To avoid the platform routing requests directly to your Web apps' Endpoints, and thus bypassing the Endpoint on which MasterProxy is running, you can configure your other Web apps' Endpoints to not start a server in your production config.

```elixir
# An Endpoint on which MasterProxy is not running
config :my_app_web, MyAppWeb.Endpoint,
  # ...
  server: false
```

## How does proxying work?

1. We start a Cowboy server with a single dispatch handler: `MasterProxy.Cowboy2Handler`.
2. The handler checks the verb, host and path of the request, and compares them to the supplied configuration to determine where to route the request.
	1. If the backend that matched is a `phoenix_endpoint`, MasterProxy delegates to the Phoenix.Endpoint.Cowboy2Handler with your app's Endpoint.
	2. If the backend that matched is a `plug`, MasterProxy simply calls the plug as normal.
	3. If no backend is matched, a text response with a status code of 404 is returned.

## Development

```bash
mix run --no-halt
curl -i foo.com.127.0.0.1.xip.io:4080 
curl -i localhost:4080
```

## Configuration examples

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
