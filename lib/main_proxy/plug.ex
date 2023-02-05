defmodule MainProxy.Plug do
  require Logger

  @not_found_backend %{
    plug: MainProxy.Plug.NotFound
  }

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    backends = Keyword.fetch!(opts, :backends)

    backend = choose_backend(conn, backends)
    log_request("Backend chosen: #{inspect(backend)}")

    case backend do
      %{phoenix_endpoint: phoenix_endpoint} -> phoenix_endpoint.call(conn, [])
      %{plug: plug} -> plug.call(conn, [])
    end
  end

  defp choose_backend(conn, backends) when is_list(backends) do
    Enum.find(backends, @not_found_backend, fn backend ->
      backend_matches?(conn, backend)
    end)
  end

  defp choose_backend(_conn, backends) do
    raise "Expected backends to be a list, instead got #{inspect(backends)}"
  end

  defp backend_matches?(conn, backend) do
    verb = Map.get(backend, :verb)
    domain = Map.get(backend, :domain)
    host = Map.get(backend, :host)
    path = Map.get(backend, :path)

    verb_match = if verb, do: Regex.match?(verb, conn.method), else: true
    domain_match = if domain, do: conn.host == domain, else: true
    host_match = if host, do: Regex.match?(host, conn.host), else: true
    path_match = if path, do: Regex.match?(path, conn.request_path), else: true

    verb_match && domain_match && host_match && path_match
  end

  defp log_request(message) do
    if Application.get_env(:main_proxy, :log_requests, true) do
      Logger.debug(message)
    end
  end
end
