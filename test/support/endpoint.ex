defmodule MainProxy.Test.Endpoint do
  use Phoenix.Endpoint, otp_app: :main_proxy
  plug(MainProxy.Test.Router)
end
