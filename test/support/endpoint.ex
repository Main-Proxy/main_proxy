defmodule MasterProxy.Test.Endpoint do
  use Phoenix.Endpoint, otp_app: :master_proxy
  plug(MasterProxy.Test.Router)
end
