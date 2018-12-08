defmodule MasterProxyTest do
  use ExUnit.Case
  doctest MasterProxy

  test "greets the world" do
    assert MasterProxy.hello() == :world
  end
end
