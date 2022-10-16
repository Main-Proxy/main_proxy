defmodule MainProxy.Test.Router do
  use Phoenix.Router

  get "/", MainProxy.Test.PageController, :index
end
