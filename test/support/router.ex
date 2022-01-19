defmodule MasterProxy.Test.Router do
  use Phoenix.Router

  get "/", MasterProxy.Test.PageController, :index
end
