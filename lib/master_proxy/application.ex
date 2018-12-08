defmodule MasterProxy.Application do
  @moduledoc false
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    options = %{
      backends: Application.get_env(:master_proxy, :backends)
    }

    children = []

    children = Enum.reduce([:http, :https], [], fn scheme, result ->
      case Application.get_env(:master_proxy, scheme) do
        nil ->
          # no config for this scheme, that's ok, just skip
          result
        scheme_opts ->
          # Adapted from https://github.com/phoenixframework/phoenix/blob/v1.4/lib/phoenix/endpoint/supervisor.ex
          # We try to closely mirror phoenix because master_proxy actually bypasses the phoenix cowboy server
          # and uses the Endpoint plug directly.
          port = :proplists.get_value(:port, scheme_opts)
          opts = [port: port_to_integer(port)] ++ :proplists.delete(:port, scheme_opts)
          Logger.info "[master_proxy] Listening on #{scheme} with options: #{inspect opts}"

          # TODO: do websockets work?
          [{Plug.Cowboy, scheme: scheme, plug: {MasterProxy.Plug, options}, options: opts} | result]
      end
    end)

    opts = [strategy: :one_for_one, name: MasterProxy.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # :undefined is what :proplist.get_value returns
  defp port_to_integer(:undefined), do: raise "port is missing from the master_proxy configuration"
  defp port_to_integer(port) when is_binary(port), do: String.to_integer(port)
  defp port_to_integer(port) when is_integer(port), do: port
end
