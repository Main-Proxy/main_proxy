# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## 0.3.1 - 2023-07-27

Updates deps

## 0.3.0 - 2023-03-05

New feature: Support Phoenix 1.7

Breaking change: Only Phoenix 1.7 and higher is now supported, if you need to
support an earlier version of Phoenix then you need to use an earlier version of
MainProxy. This was necessary because Phoenix 1.7 had large changes in how
websockets worked. See https://github.com/Main-Proxy/main_proxy/pull/31 for
details.

## 0.2.0 - 2022-10-15

Breaking change: Project has been renamed from `master_proxy` to `main_proxy`.
To upgrade your project do a search and replace of:
- `MasterProxy` -> `MainProxy`
- `master_proxy` -> `main_proxy`

The flexibility of MainProxy has been increased and it is now possible to
generate configuration at runtime during application startup.

Breaking change: You must create a `MyApp.Proxy` module that calls `use
MainProxy`. This allows configuration to be generated at runtime which is
important for usage with SiteEncrypt along with other setups.

Example module:

```elixir
defmodule MyApp.Proxy do
  use MainProxy.Proxy
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

You can also move your `backends` configuration into your `MyApp.Proxy` module
instead of inside application configuration. This change is in line with the
["Avoid application
configuration"](https://hexdocs.pm/elixir/1.13/library-guidelines.html#avoid-application-configuration)
library guideline.

See `MainProxy.Proxy` docs for details about the new module.

## 0.1.4 - 2022-01-21
### Added
- Add server and domain options [#16](https://github.com/Main-Proxy/main_proxy/pull/16)
  - Domain allows you to check if a request matches the given domain without using a regex
  - server allows you to prevent MainProxy from starting unless you run `mix phx.server` (fixes [#8](https://github.com/Main-Proxy/main_proxy/issues/8))

## Previous Releases

See the commit history and pull requests for details: https://github.com/Main-Proxy/main_proxy/commits/main
