defmodule MasterProxy.Plug do
  import Plug.Conn

  def init(options) do
    options
  end

  def call(conn, _opts) do
    # TODO: fill this in.
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello world")
  end
end

