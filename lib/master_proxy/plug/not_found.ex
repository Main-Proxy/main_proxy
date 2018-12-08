defmodule MasterProxy.Plug.NotFound do
  import Plug.Conn
  require Logger

  def init(options) do
    options
  end

  def call(conn, opts) do
    Logger.debug "MasterProxy.NotFound call opts: #{inspect opts}"
    conn
    |> send_resp(404, "No backends matched")
  end

end
