defmodule MasterProxy.Proxy do
  @moduledoc """
  Defines a proxy

  Allows defining an http and/or https proxy.

  Basic example:

      defmodule MyApp.Proxy do
        use MasterProxy.Proxy
      end

  Example with [SiteEncrypt](https://hex.pm/packages/site_encrypt):

      defmodule MyApp.Proxy do
        use MasterProxy.Proxy

        @impl MasterProxy.Proxy
        def merge_config(:https, opts) do
          Config.Reader.merge(opts, SiteEncrypt.https_keys(MyAppWeb.Endpoint))
        end

        def merge_config(_, opts), do: opts
      end
  """

  @type scheme :: :http | :https

  @doc """
  Overriding this callback allows the configuration from the application
  environment to be modified at runtime.

  Receives configuration from application environment. By default the
  application environment configuration is used.
  """
  @callback merge_config(scheme(), keyword()) :: keyword()

  @optional_callbacks merge_config: 2

  require Logger

  defmacro __using__(_opts) do
    quote do
      use Supervisor

      @behaviour MasterProxy.Proxy

      def start_link(opts \\ []) do
        Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
      end

      @impl Supervisor
      def init(callback_module) do
        backends = Application.fetch_env!(:master_proxy, :backends)

        children =
          if MasterProxy.Proxy.server?() do
            MasterProxy.Proxy.spec([backends: backends, callback_module: __MODULE__], __MODULE__)
          else
            []
          end

        Supervisor.init(children, strategy: :one_for_one)
      end

      def merge_config(_scheme, opts), do: opts

      defoverridable merge_config: 2
    end
  end

  # Builds the spec for each Plug.Cowboy process
  @doc false
  def spec(handler_opts, callback_module) do
    Enum.reduce([:http, :https], [], fn scheme, result ->
      case Application.get_env(:master_proxy, scheme) do
        nil ->
          # no config for this scheme, that's ok, just skip
          result

        scheme_opts ->
          opts = build_opts(scheme, scheme_opts, handler_opts, callback_module)

          Logger.info("[master_proxy] Listening on #{scheme} with options: #{inspect(opts)}")

          [{Plug.Cowboy, scheme: scheme, plug: {nil, nil}, options: opts} | result]
      end
    end)
  end

  defp build_opts(scheme, scheme_opts, handler_opts, callback_module) do
    port = :proplists.get_value(:port, scheme_opts)
    dispatch = [{:_, [{:_, MasterProxy.Cowboy2Handler, {nil, handler_opts}}]}]

    opts =
      callback_module.merge_config(scheme,
        port: port_to_integer(port),
        dispatch: dispatch
      )

    opts ++ :proplists.delete(:port, scheme_opts)
  end

  @doc false
  def server?() do
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
