defmodule MasterProxy do
  @moduledoc false
  use Supervisor
  import Supervisor.Spec, warn: false
  require Logger

  def child_spec(opts) do
    %{
      id: opts[:name] || __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def init(opts), do: {:ok, opts}

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)

    load_runtime_config(opts)

    children =
      Enum.reduce([:http, :https], [], fn scheme, result ->
        case Application.get_env(:master_proxy, scheme) do
          nil ->
            # no config for this scheme, that's ok, just skip
            result

          scheme_opts ->
            port = :proplists.get_value(:port, scheme_opts)

            cowboy_opts =
              [
                port: port_to_integer(port),
                dispatch: [{:_, [{:_, MasterProxy.Cowboy2Handler, {nil, nil}}]}]
              ] ++ :proplists.delete(:port, scheme_opts)

            Logger.info("[master_proxy] Listening on #{scheme} with options: #{inspect(opts)}")

            [{Plug.Cowboy, scheme: scheme, plug: {nil, nil}, options: cowboy_opts} | result]
        end
      end)

    supervisor_opts = [strategy: :one_for_one, name: :"#{name}.Supervisor"]
    Supervisor.start_link(children, supervisor_opts)
  end

  defp load_runtime_config(options) do
    if Keyword.keyword?(options) do
      Enum.each(options, fn {key, value} ->
        Application.put_env(:master_proxy, key, value)
      end)
    else
      raise("the options provided to MasterProxy must be a keyword list")
    end
  end

  # :undefined is what :proplist.get_value returns
  defp port_to_integer(:undefined),
    do: raise("port is missing from the master_proxy configuration")

  defp port_to_integer(port) when is_binary(port), do: String.to_integer(port)
  defp port_to_integer(port) when is_integer(port), do: port
end
