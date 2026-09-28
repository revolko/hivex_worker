defmodule HivexWorker.Handler do
  @moduledoc """
  The main interface for the worker.

  It is meant to be called by the Hivex main application -- will see what is possible.
  """

  require Logger

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Starts a container and creates hivex proxy tunnel for it.
  """
  def start_container() do
    dummy_server = %HivexProxyClient.Server{ip: :localhost, port: 4050, proxy_listener_port: 8080}
    :ok = GenServer.call(__MODULE__, {:start_container, "dummy", dummy_server})
  end

  @doc """
  Stops and removes a container and kills its hivex proxy tunnel.
  """
  def remove_container() do
    :ok = GenServer.call(__MODULE__, {:remove_container, "dummy"})
  end

  @impl true
  def init([]) do
    {:ok, %{servers: %{}}}
  end

  @impl true
  def handle_call({:start_container, name, %HivexProxyClient.Server{} = server}, _from, state) do
    Logger.debug(message: "Starting a new container", name: name, server: server)
    HivexWorker.DockerContainersManager.create_container()
    HivexWorker.DockerContainersManager.start_container()
    {:ok, pid} = HivexProxyClient.ConnectionsSupervisor.register_server(server)

    servers = Map.put(state.servers, name, pid)
    state = %{state | servers: servers}
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:remove_container, name}, _from, state) do
    Logger.debug(message: "Stopping container", name: name)

    {tunnel_client_pid, servers} = Map.pop(state.servers, name)
    HivexWorker.DockerContainersManager.stop_container()
    HivexWorker.DockerContainersManager.remove_container()
    HivexProxyClient.ConnectionsSupervisor.deregister_server(tunnel_client_pid)

    state = %{state | servers: servers}
    {:reply, :ok, state}
  end
end
