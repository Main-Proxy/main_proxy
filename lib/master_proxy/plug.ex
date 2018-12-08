defmodule MasterProxy.Plug do
  require Logger

  def init(options) do
    options
  end

  def call(conn, opts) do
    # TODO: fill this in.
    Logger.debug "MasterProxy.Plug call opts: #{inspect opts}"
    backend = choose_backend(conn, opts[:backends])
    dispatch(conn, backend)
  end

  defp choose_backend(_conn, backends) do
    List.first(backends)
  end

  defp dispatch(conn, backend) do
    backend[:plug].call(conn, backend[:opts])
  end
end

