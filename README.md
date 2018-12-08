# MasterProxy

Proxies requests to Web apps that are part of the platform. Useful for Heroku deployment when just one web port is exposed.

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

## Development

```bash
mix run --no-halt
curl -i foo.com.127.0.0.1.xip.io:3333 # matches host
curl -i localhost:3333 # not found case
```
