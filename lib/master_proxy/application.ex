defmodule MasterProxy.Application do
  @moduledoc false
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children =
      Enum.reduce([:http, :https], [], fn scheme, result ->
        case Application.get_env(:master_proxy, scheme) do
          nil ->
            # no config for this scheme, that's ok, just skip
            result

          scheme_opts ->
            port = :proplists.get_value(:port, scheme_opts)
            dispatch = [ {:_, [ { :_, MasterProxy.Cowboy2Handler, {nil, nil} } ]} ]

            opts =
              [
                port: port_to_integer(port),
                dispatch: dispatch
              ] ++ :proplists.delete(:port, scheme_opts)

            Logger.info("[master_proxy] Listening on #{scheme} with options: #{inspect(opts)}")

            [{Plug.Cowboy, scheme: scheme, plug: {nil, nil}, options: opts} | result]
        end
      end)

    opts = [strategy: :one_for_one, name: MasterProxy.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # :undefined is what :proplist.get_value returns
  defp port_to_integer(:undefined),
    do: raise("port is missing from the master_proxy configuration")

  defp port_to_integer(port) when is_binary(port), do: String.to_integer(port)
  defp port_to_integer(port) when is_integer(port), do: port
end
