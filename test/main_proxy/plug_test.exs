defmodule MainProxy.PlugTest do
  use ExUnit.Case
  use Plug.Test
  use ExUnitProperties

  setup do
    {:ok, pid} = start_supervised(MainProxy.Test.Endpoint)

    {:ok, pid: pid}
  end

  defp build_req(scheme, method, host, path, headers \\ %{}) do
    %Plug.Conn{
      Plug.Test.conn(method, path)
      | scheme: scheme,
        host: host,
        req_headers: headers
    }
  end

  defp matches_domain?(backend_domain, conn_domain) do
    backends = [%{domain: backend_domain, plug: MainProxy.Plug.Test}]

    # these are the required params..
    conn = build_req("http", "GET", conn_domain, "/")

    updated_opts = MainProxy.Plug.init(backends: backends)
    conn = MainProxy.Plug.call(conn, updated_opts)

    {status, headers, body} = Plug.Test.sent_resp(conn)
    {status, headers, body}
  end

  defp matches_domain_phoenix_endpoint?(backend_domain, conn_domain) do
    backends = [%{domain: backend_domain, phoenix_endpoint: MainProxy.Test.Endpoint}]

    # these are the required params..
    conn = build_req("http", "GET", conn_domain, "/")

    updated_opts = MainProxy.Plug.init(backends: backends)
    conn = MainProxy.Plug.call(conn, updated_opts)

    {status, headers, body} = Plug.Test.sent_resp(conn)
    {status, headers, body}
  end

  defp matches_host?(backend_host, conn_host) do
    backends = [%{host: backend_host, plug: MainProxy.Plug.Test}]

    # these are the required params..
    conn = build_req("http", "GET", conn_host, "/")

    updated_opts = MainProxy.Plug.init(backends: backends)
    conn = MainProxy.Plug.call(conn, updated_opts)

    {status, headers, body} = Plug.Test.sent_resp(conn)
    {status, headers, body}
  end

  defp matches_path?(backend_path, conn_path) do
    backends = [%{path: backend_path, plug: MainProxy.Plug.Test}]

    # these are the required params..
    conn = build_req("http", "GET", "localhost", conn_path)

    updated_opts = MainProxy.Plug.init(backends: backends)
    conn = MainProxy.Plug.call(conn, updated_opts)

    {status, headers, body} = Plug.Test.sent_resp(conn)
    {status, headers, body}
  end

  defp matches_verb?(backend_verb, conn_verb) do
    backends = [%{verb: backend_verb, plug: MainProxy.Plug.Test}]

    # these are the required params..
    conn = build_req("http", conn_verb, "localhost", "/")

    updated_opts = MainProxy.Plug.init(backends: backends)
    conn = MainProxy.Plug.call(conn, updated_opts)

    {status, headers, body} = Plug.Test.sent_resp(conn)
    {status, headers, body}
  end

  defp matches_all?(backend_verb, backend_host, backend_path, conn_verb, conn_host, conn_path) do
    backends = [
      %{
        verb: backend_verb,
        domain: conn_host,
        host: backend_host,
        path: backend_path,
        plug: MainProxy.Plug.Test
      }
    ]

    # these are the required params..
    conn = build_req("http", conn_verb, conn_host, conn_path)

    updated_opts = MainProxy.Plug.init(backends: backends)
    conn = MainProxy.Plug.call(conn, updated_opts)

    {status, headers, body} = Plug.Test.sent_resp(conn)
    {status, headers, body}
  end

  defp host_generator do
    # TODO: include hyphens?
    gen all domain <- string(:alphanumeric) do
      "#{domain}.com"
    end
  end

  defp path_generator do
    string([?a..?z, ?/, ?0..?9])
    # Plug requires that the path always start with /
    |> map(fn
      "/" <> _ = path -> path
      path -> "/" <> path
    end)
  end

  defp verb_generator do
    member_of(["GET", "POST", "PUT", "HEAD", "DELETE", "PATCH"])
  end

  property "all domains match themselves" do
    check all host <- host_generator() do
      {status, _headers, _body} = matches_domain?(host, host)
      assert status == 200
    end
  end

  property "all domains match themselves phoenix_endpoint" do
    check all host <- host_generator() do
      {status, _headers, _body} = matches_domain_phoenix_endpoint?(host, host)
      assert status == 200
    end
  end

  property "all hosts match themselves" do
    # TODO: include hyphens?
    check all host <- host_generator() do
      {status, _headers, _body} = matches_host?(Regex.compile!(host), host)
      assert status == 200
    end
  end

  property "all hosts match unspecified host" do
    check all host <- host_generator() do
      {status, _headers, _body} = matches_host?(nil, host)
      assert status == 200
    end
  end

  property "all hosts match subset" do
    check all host <- host_generator() do
      {status, _headers, _body} = matches_host?(Regex.compile!(String.slice(host, 1..-1)), host)
      assert status == 200
    end
  end

  property "all hosts match empty string" do
    check all host <- host_generator() do
      {status, _headers, _body} = matches_host?(Regex.compile!(""), host)
      assert status == 200
    end
  end

  property "no hosts match" do
    check all host <- host_generator() do
      {status, _headers, _body} = matches_host?(Regex.compile!("#{host}extra"), host)
      assert status == 404
    end
  end

  property "all paths match prefix" do
    check all path <- path_generator() do
      {status, _headers, _body} =
        matches_path?(Regex.compile!("^" <> String.slice(path, 0..1)), path)

      assert status == 200
    end
  end

  property "all verbs match case insensitively" do
    check all verb <- verb_generator() do
      {status, _headers, _body} =
        matches_verb?(Regex.compile!(verb, [:caseless]), String.upcase(verb))

      assert status == 200
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

      assert status == 200
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

      assert status == 404
    end
  end
end
