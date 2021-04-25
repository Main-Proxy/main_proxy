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
  def init(req, {_endpoint, _opts}) do
    log_request("MasterProxy.Cowboy2Handler called with req: #{inspect(req)}")

    conn = connection().conn(req)

    # extract this and pass in as a param somehow
    backends = Application.get_env(:master_proxy, :backends)

    backend = choose_backend(conn, backends)
    log_request("Backend chosen: #{inspect(backend)}")

    req = execute_cowboy_middleware(req, backend)

    dispatch(backend, req)
  end

  defp choose_backend(conn, backends) do
    Enum.find(backends, @not_found_backend, fn backend ->
      backend_matches?(conn, backend)
    end)
  end

  defp execute_cowboy_middleware(req, %{cowboy_middleware: cowboy_middlewares}) when is_list(cowboy_middlewares) do
    cowboy_middlewares
    |> Enum.reduce(req, fn cowboy_middleware, req -> cowboy_middleware.(req) end)
  end

  defp execute_cowboy_middleware(req, %{cowboy_middleware: cowboy_middleware}) when is_function(cowboy_middleware) do
    cowboy_middleware.(req)
  end

  defp execute_cowboy_middleware(req, _), do: req

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
    verb = Map.get(backend, :verb) || ~r/.*/
    host = Map.get(backend, :host) || ~r/.*/
    path = Map.get(backend, :path) || ~r/.*/

    Regex.match?(host, conn.host) && Regex.match?(path, conn.request_path) &&
      Regex.match?(verb, conn.method)
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
