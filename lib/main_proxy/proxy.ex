defmodule MainProxy.Proxy do
  require Logger

  @doc """
  Specify the backends to pass requests to at startup time. (Optional)

  Overriding this callback allows for setting the backends to be matched at
  runtime when the proxy is starting up.

  Example:

      @impl MainProxy.Proxy
      def backends do
        [
          %{
            domain: "https://myapp1.com",
            phoenix_endpoint: MyApp1Web.Endpoint
          },
          %{
            domain: "https://myapp2.com",
            phoenix_endpoint: MyApp2Web.Endpoint
          }
        ]
      end
  """
  @callback backends :: list(map())

  @type scheme :: :http | :https
  @doc """
  Merge cowboy config

  Overriding this callback allows the configuration from the application
  environment to be modified at runtime.
  """
  @callback merge_config(scheme(), keyword()) :: keyword()

  @optional_callbacks merge_config: 2, backends: 0

  defmacro __using__(_opts) do
    quote do
      use Supervisor
      @behaviour MainProxy.Proxy

      def merge_config(_scheme, opts), do: opts
      def backends, do: MainProxy.default_fetch_backends()

      defoverridable merge_config: 2, backends: 0

      def start_link(opts \\ []) do
        Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
      end

      def init(opts) do
        backends = __MODULE__.backends()

        children =
          if MainProxy.should_start_server?() do
            MainProxy.spec([backends: backends, callback_module: __MODULE__], __MODULE__)
          else
            []
          end

        Supervisor.init(children, strategy: :one_for_one)
      end
    end
  end
end
