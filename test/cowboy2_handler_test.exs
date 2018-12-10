defmodule MasterProxy.Cowboy2HandlerTest do
  use ExUnit.Case
  use Plug.Test
  use ExUnitProperties

  @connection Plug.Cowboy.Conn

  test "no backend matches" do
    backends = [%{host: ~r/gigalixir.readthedocs.io/, plug: ""}]
    Application.put_env(:master_proxy, :backends, backends)

    req = %{
      bindings: %{},
      body_length: 0,
      cert: :undefined,
      has_body: false,
      headers: %{"accept" => "*/*", "host" => "localhost:4000", "user-agent" => "curl/7.47.0"},
      host: "localhost",
      host_info: :undefined,
      method: "GET",
      path: "/",
      path_info: :undefined,
      peer: {{0, 0, 0, 0, 0, 65535, 32512, 1}, 49020},
      pid: pid_from_string("#PID<0.1.0>"),
      port: 4000,
      qs: "",
      ref: HTTP,
      scheme: "http",
      sock: {{0, 0, 0, 0, 0, 65535, 32512, 1}, 4000},
      streamid: 1,
      version: :"HTTP/1.1"
    }

    # req = %{
    #   scheme: :http,
    #   path: "/",
    #   host: "gigalixir.com",
    #   port: 4000,
    #   method: "GET",
    #   headers: [],
    #   qs: "",
    #   peer: {"1.2.3.4", "40000"}
    # }

    # conn =
    #   conn(:get, "/")
    #   |> Map.put(:host, "gigalixir.com")

    # %{adapter: {_conn, req}} = conn
    {:ok, _req, {_handler, _opts}} = MasterProxy.Cowboy2Handler.init(req, {nil, nil})

    receive do
      {ref, {status, headers, body}} -> assert status == 404
    after
      1_000 -> flunk "timed out"
    end

    receive do
      {:plug_conn, :sent} -> assert true
    after
      1_000 -> flunk "timed out"
    end
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

  def pid_from_string("#PID" <> string) do
    string
    |> :erlang.binary_to_list()
    |> :erlang.list_to_pid()
  end
end
