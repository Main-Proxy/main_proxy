defmodule MasterProxy do
  require Logger

  @type scheme :: :http | :https

  @callback choose_backend(Plug.Conn.t()) ::
              {:phoenix_endpoint, module()} | {:plug, module()} | :fallback

  @callback merge_config(scheme(), keyword()) :: keyword()

  @optional_callbacks choose_backend: 1, merge_config: 2

  defmacro __using__(opts) do
    # TODO: Check that backends was passed at compile time
    # Maybe use a similar pattern with nimble_options as site_encrypt?

    quote do
      use Supervisor

      @behaviour MasterProxy

      def start_link(callback_module) do
        Supervisor.start_link(__MODULE__, callback_module, name: __MODULE__)
      end

      @impl Supervisor
      def init(callback_module) do
        backends = Keyword.fetch!(unquote(opts), :backends)
        children = MasterProxy.spec([backends: backends, callback_module: __MODULE__], __MODULE__)

        Supervisor.init(children, strategy: :one_for_one)
      end
    end
  end

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
      [
        port: port_to_integer(port),
        dispatch: dispatch
      ]
      |> maybe_merge_config(scheme, callback_module)

    opts ++ :proplists.delete(:port, scheme_opts)
  end

  defp maybe_merge_config(config, scheme, callback_module) do
    if function_exported?(callback_module, :merge_config, 2) do
      callback_module.merge_config(scheme, config)
    else
      config
    end
  end

  # :undefined is what :proplist.get_value returns
  defp port_to_integer(:undefined),
    do: raise("port is missing from the master_proxy configuration")

  defp port_to_integer(port) when is_binary(port), do: String.to_integer(port)
  defp port_to_integer(port) when is_integer(port), do: port
end
