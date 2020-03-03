# Copied from https://raw.githubusercontent.com/phoenixframework/phoenix/v1.4/test/phoenix/integration/websocket_socket_test.exs
defmodule MasterProxy.Integration.WebSocketTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  require Logger

  alias MasterProxy.Integration.WebsocketClient
  alias __MODULE__.Endpoint

  @moduletag :capture_log
  @port 5907
  @path "ws://127.0.0.1:#{@port}/ws/websocket"

  # TODO: how does this work? when I try to configure
  # :master_proxy here, it is too late. maybe ExUnit is
  # starting my "main" app automatically before we get here?
  Application.put_env(
    :phoenix,
    Endpoint,
    https: false,
    http: [port: @port + 1],
    debug_errors: false,
    server: true
  )

  defmodule UserSocket do
    @behaviour Phoenix.Socket.Transport

    def child_spec(opts) do
      :value = Keyword.fetch!(opts, :custom)
      Supervisor.Spec.worker(Task, [fn -> :ok end], restart: :transient)
    end

    def connect(map) do
      %{endpoint: Endpoint, params: params, transport: :websocket} = map
      {:ok, {:params, params}}
    end

    def init({:params, _} = state) do
      {:ok, state}
    end

    def handle_in({"params", opts}, {:params, params} = state) do
      :text = Keyword.fetch!(opts, :opcode)
      {:reply, :ok, {:text, inspect(params)}, state}
    end

    def handle_in({"ping", opts}, state) do
      :text = Keyword.fetch!(opts, :opcode)
      send(self(), :ping)
      {:ok, state}
    end

    def handle_info(:ping, state) do
      {:push, {:text, "pong"}, state}
    end

    def terminate(_reason, {:params, _}) do
      :ok
    end
  end

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :phoenix

    socket("/ws", UserSocket,
      websocket: [check_origin: ["//example.com"], timeout: 200],
      custom: :value
    )
  end

  setup_all do
    # capture_log(fn -> MasterProxy.start(nil, nil) end)
    # MasterProxy.start(nil, nil)
    # matches everything and proxies over to the Endpoint here
    backends = [%{phoenix_endpoint: Endpoint}]
    Application.put_env(:master_proxy, :backends, backends)
    {:ok, _pid} = MasterProxy.start_link([])
    # This needs to start so Phoenix.Config is initialized
    # among other things
    capture_log(fn -> Endpoint.start_link() end)
    :ok
  end

  test "refuses unallowed origins" do
    capture_log(fn ->
      headers = [{"origin", "https://example.com"}]
      assert {:ok, _} = WebsocketClient.start_link(self(), @path, :noop, headers)

      headers = [{"origin", "http://notallowed.com"}]
      assert {:error, {403, _}} = WebsocketClient.start_link(self(), @path, :noop, headers)
    end)
  end

  test "returns params with sync request" do
    assert {:ok, client} = WebsocketClient.start_link(self(), "#{@path}?key=value", :noop)
    WebsocketClient.send_message(client, "params")
    assert_receive {:text, ~s(%{"key" => "value"})}
  end

  test "returns pong from async request" do
    assert {:ok, client} = WebsocketClient.start_link(self(), "#{@path}?key=value", :noop)
    WebsocketClient.send_message(client, "ping")
    assert_receive {:text, "pong"}
  end
end
