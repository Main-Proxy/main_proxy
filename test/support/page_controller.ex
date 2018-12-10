defmodule MasterProxy.Test.PageController do
  use Phoenix.Controller, namespace: MasterProxy.Test

  def index(conn, _params) do
    json(conn, %{})
  end
end
