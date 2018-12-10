defmodule MasterProxy.Test.Router do
  use Phoenix.Router
  import Plug.Conn
  import Phoenix.Controller

  get("/", MasterProxy.Test.PageController, :index)
end
