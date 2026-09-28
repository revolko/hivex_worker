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

  ## Parameters

   * `name` - name of the container
   * `image_name` - image name
   * `container_port` - internal container port
   * `exposed_port` - externa (host) port mapped to the container
   * `proxy_port` - proxy server listener port
  """
  def start_container(name, image_name, container_port, exposed_port, proxy_port, opts \\ []) do
    :ok =
      GenServer.call(
        __MODULE__,
        {:start_container, name, image_name, container_port, exposed_port, proxy_port, opts}
      )
  end

  @doc """
  Stops and removes a container and kills its hivex proxy tunnel.

  ## Parameters

   * `container_id` - name or ID of the container
  """
  def delete_container(container_id) do
    :ok = GenServer.call(__MODULE__, {:delete_container, container_id})
  end

  @impl true
  def init([]) do
    {:ok, %{servers: %{}}}
  end

  @impl true
  def handle_call(
        {:start_container, name, image_name, container_port, exposed_port, proxy_port, opts},
        _from,
        state
      ) do
    Logger.debug(
      message: "Starting a new container",
      name: name,
      image: image_name,
      container_port: container_port,
      exposed_port: exposed_port,
      proxy_port: proxy_port
    )

    server = %HivexProxyClient.Server{
      ip: :localhost,
      port: exposed_port,
      proxy_listener_port: proxy_port
    }

    with {:ok, %{"Id" => container_id}} <-
           HivexWorker.DockerContainersManager.create_container(
             name,
             image_name,
             container_port,
             exposed_port,
             opts
           ),
         {:ok, _} <- HivexWorker.DockerContainersManager.start_container(container_id),
         {:ok, pid} <- HivexProxyClient.ConnectionsSupervisor.register_server(server) do
      servers = Map.put(state.servers, name, pid)
      state = %{state | servers: servers}
      {:reply, :ok, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:delete_container, name}, _from, state) do
    Logger.debug(message: "Stopping container", name: name)

    {tunnel_client_pid, servers} = Map.pop(state.servers, name)

    with {:ok, _} <- HivexWorker.DockerContainersManager.delete_container(name, force: true),
         :ok <- HivexProxyClient.ConnectionsSupervisor.deregister_server(tunnel_client_pid) do
      state = %{state | servers: servers}
      {:reply, :ok, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end
end
