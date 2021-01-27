defmodule MasterProxy.Cowboy2Handler do
  require Logger

  @moduledoc false

  defp connection() do
    Application.get_env(:master_proxy, :conn, Plug.Cowboy.Conn)
  end

  defp log_request(message) do
    if Application.get_env(:master_proxy, :log_requests, true) do
      Logger.debug(message)
    end
  end

  @not_found_backend %{
    plug: MasterProxy.Plug.NotFound
  }

  # endpoint and opts are not passed in because they
  # are dynamically chosen
  def init(req, {_endpoint, opts}) do
    log_request("MasterProxy.Cowboy2Handler called with req: #{inspect(req)}")

    conn = connection().conn(req)

    backend = choose_backend(conn, opts)
    log_request("Backend chosen: #{inspect(backend)}")

    dispatch(backend, req)
  end

  defp choose_backend(conn, opts) do
    callback_module = Keyword.get(opts, :callback_module)
    backends = Keyword.fetch!(opts, :backends)

    if callback_module && function_exported?(callback_module, :choose_backend, 1) do
      case callback_module.choose_backend(conn) do
        :fallback -> choose_backend_from_config(conn, backends)
        {:phoenix_endpoint, endpoint} -> %{phoenix_endpoint: endpoint}
        {:plug, plug} -> %{plug: plug}
      end
    else
      choose_backend_from_config(conn, backends)
    end
  end

  defp choose_backend_from_config(conn, backends) do
    Enum.find(backends, @not_found_backend, fn backend ->
      backend_matches?(conn, backend)
    end)
  end

  defp dispatch(%{phoenix_endpoint: endpoint}, req) do
    # we don't pass in any opts here because that is how phoenix does it
    # see https://github.com/phoenixframework/phoenix/blob/v1.5.7/lib/phoenix/endpoint/cowboy2_adapter.ex#L41
    Phoenix.Endpoint.Cowboy2Handler.init(req, {endpoint, endpoint.init([])})
  end

  defp dispatch(%{plug: plug} = backend, req) do
    conn = connection().conn(req)

    opts = Map.get(backend, :opts, [])
    handler = plug

    # Copied from https://github.com/phoenixframework/phoenix/blob/master/lib/phoenix/endpoint/cowboy2_handler.ex
    c = connection()

    %{adapter: {^c, req}} =
      conn
      |> handler.call(opts)
      |> maybe_send(handler)

    {:ok, req, {handler, opts}}
  end

  # Copied from https://github.com/phoenixframework/phoenix/blob/master/lib/phoenix/endpoint/cowboy2_handler.ex
  defp maybe_send(%Plug.Conn{state: :unset}, _plug), do: raise(Plug.Conn.NotSentError)
  defp maybe_send(%Plug.Conn{state: :set} = conn, _plug), do: Plug.Conn.send_resp(conn)
  defp maybe_send(%Plug.Conn{} = conn, _plug), do: conn

  defp maybe_send(other, plug) do
    raise "MasterProxy expected #{inspect(plug)} to return Plug.Conn but got: " <> inspect(other)
  end

  defp backend_matches?(conn, backend) do
    domain = Map.get(backend, :domain)
    verb = Map.get(backend, :verb) || ~r/.*/
    host = Map.get(backend, :host) || ~r/.*/
    path = Map.get(backend, :path) || ~r/.*/

    verb_host_path_match =
      Regex.match?(host, conn.host) && Regex.match?(path, conn.request_path) &&
        Regex.match?(verb, conn.method)

    if domain do
      domain == conn.host && verb_host_path_match
    else
      verb_host_path_match
    end
  end

  ## Websocket callbacks
  # Copied from https://github.com/phoenixframework/phoenix/blob/master/lib/phoenix/endpoint/cowboy2_handler.ex
  def websocket_init([handler | state]) do
    {:ok, state} = handler.init(state)
    {:ok, [handler | state]}
  end

  def websocket_handle({opcode, payload}, [handler | state]) when opcode in [:text, :binary] do
    handle_reply(handler, handler.handle_in({payload, opcode: opcode}, state))
  end

  def websocket_handle(_other, handler_state) do
    {:ok, handler_state}
  end

  def websocket_info(message, [handler | state]) do
    handle_reply(handler, handler.handle_info(message, state))
  end

  def terminate(_reason, _req, {_handler, _state}) do
    :ok
  end

  def terminate({:error, :closed}, _req, [handler | state]) do
    handler.terminate(:closed, state)
  end

  def terminate({:remote, :closed}, _req, [handler | state]) do
    handler.terminate(:closed, state)
  end

  def terminate({:remote, code, _}, _req, [handler | state])
      when code in 1000..1003 or code in 1005..1011 or code == 1015 do
    handler.terminate(:closed, state)
  end

  def terminate(:remote, _req, [handler | state]) do
    handler.terminate(:closed, state)
  end

  def terminate(reason, _req, [handler | state]) do
    handler.terminate(reason, state)
  end

  defp handle_reply(handler, {:ok, state}), do: {:ok, [handler | state]}
  defp handle_reply(handler, {:push, data, state}), do: {:reply, data, [handler | state]}

  defp handle_reply(handler, {:reply, _status, data, state}),
    do: {:reply, data, [handler | state]}

  defp handle_reply(handler, {:stop, _reason, state}), do: {:stop, [handler | state]}
end
