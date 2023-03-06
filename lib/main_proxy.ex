defmodule MainProxy do
  @external_resource "README.md"

  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  require Logger

  @doc false
  def should_start_server?() do
    # the server will be started in following situations:
    # - enable `server: true` option for main_proxy (by default)
    # - run `iex -S mix phx.server`
    # - run `mix phx.server`
    Application.get_env(:phoenix, :serve_endpoints, false) ||
      Application.get_env(:main_proxy, :server, true)
  end

  # Builds the spec for each Plug.Cowboy process
  @doc false
  def spec(handler_opts, callback_module) do
    Enum.reduce([:http, :https], [], fn scheme, result ->
      case Application.get_env(:main_proxy, scheme) do
        nil ->
          # no config for this scheme, that's ok, just skip
          result

        scheme_opts ->
          backends = Keyword.fetch!(handler_opts, :backends)
          opts = build_opts(scheme, scheme_opts, handler_opts, callback_module)

          Logger.info("[main_proxy] Listening on #{scheme} with options: #{inspect(opts)}")

          [
            {
              Plug.Cowboy,
              scheme: scheme, plug: {MainProxy.Plug, backends: backends}, options: opts
            }
            | result
          ]
      end
    end)
  end

  defp build_opts(scheme, scheme_opts, _handler_opts, callback_module) do
    port = :proplists.get_value(:port, scheme_opts)

    opts =
      callback_module.merge_config(scheme,
        port: port_to_integer(port)
      )

    opts ++ :proplists.delete(:port, scheme_opts)
  end

  @doc false
  def default_fetch_backends do
    case Application.fetch_env(:main_proxy, :backends) do
      {:ok, backends} ->
        backends

      :error ->
        Logger.warn(
          "No backends specified. Either configure :main_proxy, :backends or define a " <>
            "`backend/0` function in your `Proxy` module."
        )
    end
  end

  # :undefined is what :proplist.get_value returns
  defp port_to_integer(:undefined),
    do: raise("port is missing from the main_proxy configuration")

  defp port_to_integer(port) when is_binary(port), do: String.to_integer(port)
  defp port_to_integer(port) when is_integer(port), do: port
end
