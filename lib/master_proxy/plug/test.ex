defmodule MasterProxy.Plug.Test do
  import Plug.Conn
  require Logger

  def init(options) do
    options
  end

  def call(conn, opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Test")
  end

end
