defmodule MainProxy.Test.PageController do
  use Phoenix.Controller, namespace: MainProxy.Test

  def index(conn, _params) do
    json(conn, %{})
  end
end
