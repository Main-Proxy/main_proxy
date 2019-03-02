defmodule MasterProxy.Plug.Test do
  @moduledoc false
  @behaviour Plug

  import Plug.Conn
  require Logger

  @impl true
  def init(options) do
    options
  end

  @impl true
  def call(conn, opts) do
    Logger.debug("#{__MODULE__} called with opts #{inspect(opts)}")

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "conn: #{inspect(conn)}\nopts: #{inspect(opts)}")
  end
end
