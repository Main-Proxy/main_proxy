defmodule MasterProxy.Cowboy2HandlerPhoenixEndpointTest do
  use ExUnit.Case
  use Plug.Test
  use ExUnitProperties

  setup do
    {:ok, pid} = start_supervised(MasterProxy.Test.Endpoint)

    {:ok, pid: pid}
  end

  defp build_req(scheme, method, host, path, headers \\ %{}) do
    %{
      path: path,
      host: host,
      port: 4000,
      method: method,
      headers: headers,
      qs: "",
      peer: {{0, 0, 0, 0, 0, 65535, 32512, 1}, 49020},
      scheme: scheme,
      version: :"HTTP/1.1",
      streamid: 1,
      pid: self(),
      cert: :undefined
    }
  end

  defp matches_host?(backend_host, conn_host) do
    # opts = %{backends: [%{host: backend_host, plug: MasterProxy.Plug.Test}]}

    # conn(:get, "/")
    # |> Map.put(:host, conn_host)
    # |> MasterProxy.Plug.call(MasterProxy.Plug.init(opts))

    backends = [%{host: backend_host, phoenix_endpoint: MasterProxy.Test.Endpoint}]
    Application.put_env(:master_proxy, :backends, backends)

    # these are the required params..
    req = build_req("http", "GET", conn_host, "/")
    {:ok, _req, {_handler, _opts}} = MasterProxy.Cowboy2Handler.init(req, {nil, nil})

    my_pid = self()
    stream_id = 1

    receive do
      {{^my_pid, ^stream_id}, {:response, status, headers, body}} ->
        {status, headers, body}
        # otherwise -> IO.inspect otherwise
    after
      0 -> flunk("timed out")
    end
  end

  defp host_generator do
    # TODO: include hyphens?
    gen all domain <- string(:alphanumeric) do
      "#{domain}.com"
    end
  end

  property "all hosts match themselves" do
    # TODO: include hyphens?
    check all host <- host_generator() do
      {status, _headers, _body} = matches_host?(Regex.compile!(host), host)
      assert status == "200 OK"
    end
  end

  property "all hosts match unspecified host" do
    check all host <- host_generator() do
      {status, _headers, _body} = matches_host?(nil, host)
      assert status == "200 OK"
    end
  end

  property "all hosts match subset" do
    check all host <- host_generator() do
      {status, _headers, _body} = matches_host?(Regex.compile!(String.slice(host, 1..-1)), host)
      assert status == "200 OK"
    end
  end

  property "all hosts match empty string" do
    check all host <- host_generator() do
      {status, _headers, _body} = matches_host?(Regex.compile!(""), host)
      assert status == "200 OK"
    end
  end

  property "no hosts match" do
    check all host <- host_generator() do
      {status, _headers, _body} = matches_host?(Regex.compile!("#{host}extra"), host)
      assert status == "404 Not Found"
    end
  end

  def pid_from_string("#PID" <> string) do
    string
    |> :erlang.binary_to_list()
    |> :erlang.list_to_pid()
  end
end
