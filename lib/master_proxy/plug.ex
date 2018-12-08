defmodule MasterProxy.Plug do
  require Logger

  @not_found_backend %{
    plug: MasterProxy.Plug.NotFound
  }

  def init(%{backends: [%{host: _host, plug: _plug}|_rest]}=options) do
    options
  end

  def call(conn, opts) do
    # TODO: fill this in.
    Logger.debug "MasterProxy.Plug call opts: #{inspect opts}"
    backend = choose_backend(conn, opts[:backends])
    dispatch(conn, backend)
  end

  defp choose_backend(conn, backends) do
    Enum.find(backends, @not_found_backend, fn backend ->
      backend_matches?(conn, backend)
    end)
  end

  defp dispatch(conn, backend) do
    backend[:plug].call(conn, backend[:opts])
  end

  defp backend_matches?(conn, backend) do
    verb = Map.get(backend, :verb) || ~r/.*/
    host = Map.get(backend, :host) || ~r/.*/
    path = Map.get(backend, :path) || ~r/.*/
    Regex.match?(host, conn.host) && Regex.match?(path, conn.request_path) && Regex.match?(verb, conn.method)
  end

  defp host_matches?(conn_host, host) do
    # TODO: cache result since host is likely to be repeated frequently
  end

  defp path_matches?(conn_path, path) do
    {:ok, path_regex} = Regex.compile(path)
    Regex.match?(path_regex, conn_path)
  end

  defp verb_matches?(conn_verb, verb) do
    {:ok, verb_regex} = Regex.compile(verb)
    Regex.match?(verb_regex, conn_verb)
  end
end

