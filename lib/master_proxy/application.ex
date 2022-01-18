defmodule MasterProxy.Application do
  @moduledoc false
  use Application
  require Logger

  def start(_type, _args) do
    children = children(server?())

    opts = [strategy: :one_for_one, name: MasterProxy.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp children(false), do: []

  defp children(true) do
    Enum.reduce([:http, :https], [], fn scheme, result ->
      case Application.get_env(:master_proxy, scheme) do
        nil ->
          # no config for this scheme, that's ok, just skip
          result

        scheme_opts ->
          port = :proplists.get_value(:port, scheme_opts)
          dispatch = [{:_, [{:_, MasterProxy.Cowboy2Handler, {nil, nil}}]}]

          opts =
            [
              port: port_to_integer(port),
              dispatch: dispatch
            ] ++ :proplists.delete(:port, scheme_opts)

          Logger.info("[master_proxy] Listening on #{scheme} with options: #{inspect(opts)}")

          [{Plug.Cowboy, scheme: scheme, plug: {nil, nil}, options: opts} | result]
      end
    end)
  end

  defp server?() do
    # the server will be started in following situations:
    # + enable `server: true` option for master_proxy (by default)
    # + run `iex -S mix phx.server`
    # + run `mix phx.server`
    Application.get_env(:phoenix, :serve_endpoints, false) ||
      Application.get_env(:master_proxy, :server, true)
  end

  # :undefined is what :proplist.get_value returns
  defp port_to_integer(:undefined),
    do: raise("port is missing from the master_proxy configuration")

  defp port_to_integer(port) when is_binary(port), do: String.to_integer(port)
  defp port_to_integer(port) when is_integer(port), do: port
end
