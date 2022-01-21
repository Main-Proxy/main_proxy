defmodule MasterProxy.Cowboy2HandlerPlugTest do
  use ExUnit.Case
  use Plug.Test
  use ExUnitProperties

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

  defp matches_domain?(backend_domain, conn_domain) do
    backends = [%{domain: backend_domain, plug: MasterProxy.Plug.Test}]
    Application.put_env(:master_proxy, :backends, backends)

    # these are the required params..
    req = build_req("http", "GET", conn_domain, "/")
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

  defp matches_host?(backend_host, conn_host) do
    backends = [%{host: backend_host, plug: MasterProxy.Plug.Test}]
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

  defp matches_path?(backend_path, conn_path) do
    backends = [%{path: backend_path, plug: MasterProxy.Plug.Test}]
    Application.put_env(:master_proxy, :backends, backends)

    # these are the required params..
    req = build_req("http", "GET", "localhost", conn_path)
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

  defp matches_verb?(backend_verb, conn_verb) do
    backends = [%{verb: backend_verb, plug: MasterProxy.Plug.Test}]
    Application.put_env(:master_proxy, :backends, backends)

    # these are the required params..
    req = build_req("http", conn_verb, "localhost", "/")
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

  defp matches_all?(backend_verb, backend_host, backend_path, conn_verb, conn_host, conn_path) do
    backends = [
      %{
        verb: backend_verb,
        domain: conn_host,
        host: backend_host,
        path: backend_path,
        plug: MasterProxy.Plug.Test
      }
    ]

    Application.put_env(:master_proxy, :backends, backends)

    # these are the required params..
    req = build_req("http", conn_verb, conn_host, conn_path)
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

  defp path_generator do
    string([?a..?z, ?/, ?0..?9])
  end

  defp verb_generator do
    member_of(["get", "post", "put", "head", "delete", "patch"])
  end

  property "all domains match themselves" do
    check all host <- host_generator() do
      {status, _headers, _body} = matches_domain?(host, host)
      assert status == "200 OK"
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

  property "all paths match prefix" do
    check all path <- path_generator() do
      {status, _headers, _body} =
        matches_path?(Regex.compile!("^" <> String.slice(path, 0..1)), path)

      assert status == "200 OK"
    end
  end

  property "all verbs match case insensitively" do
    check all verb <- verb_generator() do
      {status, _headers, _body} =
        matches_verb?(Regex.compile!(verb, [:caseless]), String.upcase(verb))

      assert status == "200 OK"
    end
  end

  property "all exact match" do
    check all host <- host_generator(),
              path <- path_generator(),
              verb <- verb_generator() do
      {status, _headers, _body} =
        matches_all?(
          Regex.compile!(verb),
          Regex.compile!(host),
          Regex.compile!(path),
          verb,
          host,
          path
        )

      assert status == "200 OK"
    end
  end

  property "verb and host and path with one off" do
    check all host <- host_generator(),
              path <- path_generator(),
              verb <- verb_generator() do
      {status, _headers, _body} =
        matches_all?(
          Regex.compile!(verb),
          Regex.compile!(host),
          Regex.compile!(path),
          verb,
          String.slice(host, 0..1) <> "rando",
          path
        )

      assert status == "404 Not Found"
    end
  end

  def pid_from_string("#PID" <> string) do
    string
    |> :erlang.binary_to_list()
    |> :erlang.list_to_pid()
  end
end
