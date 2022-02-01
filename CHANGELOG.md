# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

The flexibility of MasterProxy has been increased and it is now possible to
generate configuration at runtime during application startup.

Breaking change: You must create a `MyApp.Proxy` module that calls `use
MasterProxy`. This allows configuration to be generated at runtime which is
important for usage with SiteEncrypt along with other setups.

Example module:

```elixir
defmodule MyApp.Proxy do
  use MasterProxy.Proxy
end
```

The proxy must then be explicitly started as part of your application
supervision tree. Proxies can be added to the supervision tree as follows
(usually in `MyApp.Application`):

```elixir
children = [
  # ... other children
  MyApp.Proxy,
]
```

## 0.1.4 - 2022-01-21
### Added
- Add server and domain options [#16](https://github.com/jesseshieh/master_proxy/pull/16)
  - Domain allows you to check if a request matches the given domain without using a regex
  - server allows you to prevent MasterProxy from starting unless you run `mix phx.server` (fixes [#8](https://github.com/jesseshieh/master_proxy/issues/8))

## Previous Releases

See the commit history and pull requests for details: https://github.com/jesseshieh/master_proxy/commits/master
