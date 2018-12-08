defmodule Foo.Endpoint do
  import Plug.Conn
  require Logger

  def init(options) do
    options
  end

  def call(conn, opts) do
    Logger.debug "Foo.Endpoint call opts: #{inspect opts}"
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello world")
  end

end
