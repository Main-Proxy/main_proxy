defmodule MasterProxy.Test.Adapter do
  import Plug.Adapters.Test.Conn

  def conn(req) do
    # Plug.Conn's send_resp method uses an adapter
    # We want the adapter to be Plug.Adapters.Test.Conn so
    # the message is sent to the "owner" pid which is the test
    # so we can see what the response sent was.
    #
    # The problem with using it directly is that it doesn't 
    # define a conn/1 method which Cowboy2Handler expects. That's
    # what we are doing here, defining conn/1
    #
    # I guess we could implement it in many ways, but since
    # Plug.Cowboy.Conn is what we use in production, we just
    # delegate to it to do it's thing.
    #
    # We can't just take the Cowboy.Conn and change the adapter
    # because the state alongside the adapter is also adapter
    # specific. Since we are in reality using Test.Conn, we need
    # the state to be the Test.Conn state and not the Cowboy.Conn
    # state.
    #
    # Instead of implementing it ourselves, we just delegate
    # to Test.Conn to do it's thing.
    #
    # Crazy.
    conn = Plug.Cowboy.Conn.conn(req)
    Plug.Adapters.Test.Conn.conn(
      conn, 
      conn.method, 
      conn.request_path, 
      conn.query_string
    )
  end
end
