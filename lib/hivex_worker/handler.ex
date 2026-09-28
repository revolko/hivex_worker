defmodule HivexWorker.Handler do
  @moduledoc """
  The main interface for the worker.

  It is meant to be called by the Hivex main application -- will see what is possible.
  """

  require Logger

  use GenServer

  @call_timeout 30_000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Starts a container and creates hivex proxy tunnel for it.

  ## Parameters

   * `name` - name of the container
   * `image_name` - image name
   * `container_port` - internal container port
   * `exposed_port` - external (host) port mapped to the container; cannot be 0
   * `proxy_port` - proxy server listener port

  ## Example

      iex> HivexWorker.Handler.start_container("test", "fedora", 8080, 8080, 1667)
      :ok
  """
  def start_container(name, image_name, container_port, exposed_port, proxy_port, opts \\ [])
      # TODO: get rid of the when
      when exposed_port != 0 do
    GenServer.call(
      __MODULE__,
      {:start_container, name, image_name, container_port, exposed_port, proxy_port, opts},
      @call_timeout
    )
  end

  @doc """
  Stops and removes a container and kills its hivex proxy tunnel.

  ## Parameters

   * `container_id` - name or ID of the container

  ## Example

      iex> HivexWorker.Handler.delete_container("test")
      :ok
  """
  def delete_container(container_id) do
    GenServer.call(__MODULE__, {:delete_container, container_id}, @call_timeout)
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

    Logger.debug(server: server)

    case HivexWorker.DockerContainersManager.create_container(
           name,
           image_name,
           container_port,
           exposed_port,
           opts
         ) do
      {:ok, %{"Id" => container_id}} ->
        with {:ok, _} <- HivexWorker.DockerContainersManager.start_container(container_id),
             {:ok, pid} <- HivexProxyClient.ConnectionsSupervisor.register_server(server) do
          servers = Map.put(state.servers, container_id, pid)
          state = %{state | servers: servers}
          {:reply, :ok, state}
        else
          {:error, reason} ->
            Logger.error(message: "Failed to start/register container", reason: reason)
            HivexWorker.DockerContainersManager.delete_container(container_id, force: true)
            {:reply, {:error, reason}, state}
        end

      {:error, reason} ->
        Logger.error(message: "Failed to create container", reason: reason)
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:delete_container, name}, _from, state) do
    Logger.debug(message: "Stopping container", name: name)

    with {:ok, container_id} = HivexWorker.DockerContainersManager.get_container_id(name),
         {:ok, _} <-
           HivexWorker.DockerContainersManager.delete_container(container_id, force: true),
         {tunnel_client_pid, servers} <- Map.pop(state.servers, container_id),
         :ok <- deregister_server(tunnel_client_pid) do
      state = %{state | servers: servers}
      {:reply, :ok, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  defp deregister_server(nil), do: :ok

  defp deregister_server(pid) do
    HivexProxyClient.ConnectionsSupervisor.deregister_server(pid)
  catch
    :exit, {:noproc, _} ->
      Logger.warning(message: "Proxy connection process already killed", pid: pid)
      {:error, :noproc}
  end
end
