defmodule MasterProxy.PlugTest do
  use ExUnit.Case
  use Plug.Test
  use ExUnitProperties

  test "no backend matches" do
    opts = %{backends: [%{host: ~r/gigalixir.readthedocs.io/, plug: ""}]}

    conn =
      conn(:get, "/")
      |> Map.put(:host, "gigalixir.com")
      |> MasterProxy.Plug.call(MasterProxy.Plug.init(opts))

    assert conn.state == :sent
    assert conn.status == 404
  end

  defp matches_host?(backend_host, conn_host) do
    opts = %{backends: [%{host: backend_host, plug: MasterProxy.Plug.Test}]}

    conn(:get, "/")
    |> Map.put(:host, conn_host)
    |> MasterProxy.Plug.call(MasterProxy.Plug.init(opts))
  end

  defp host_generator do
    # TODO: include hyphens?
    gen all domain <- string(:alphanumeric) do
      "#{domain}.com"
    end
  end

  property "all hosts match themselves" do
    # TODO: include hyphens?
    check all host <- host_generator do
      conn = matches_host?(Regex.compile!(host), host)
      assert conn.status == 200
    end
  end

  property "all hosts match unspecified host" do
    check all host <- host_generator do
      conn = matches_host?(nil, host)
      assert conn.status == 200
    end
  end

  property "all hosts match subset" do
    check all host <- host_generator do
      conn = matches_host?(Regex.compile!(String.slice(host, 1..-1)), host)
      assert conn.status == 200
    end
  end

  property "all hosts match empty string" do
    check all host <- host_generator do
      conn = matches_host?(Regex.compile!(""), host)
      assert conn.status == 200
    end
  end
end
