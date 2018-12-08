defmodule MasterProxy.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    port = (System.get_env("PORT") || "3333") |> String.to_integer

    children = [
      {Plug.Cowboy, scheme: :http, plug: MasterProxy.Plug, options: [port: port]}
    ]

    opts = [strategy: :one_for_one, name: MasterProxy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
