defmodule MasterProxy.Plug do
  require Logger

  @not_found_backend %{
    plug: MasterProxy.Plug.NotFound
  }

  def init(options) do
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
    {:ok, host_regex} = Regex.compile(backend[:host])
    Regex.match?(host_regex, conn.host)
  end
end

