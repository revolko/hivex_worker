defmodule HivexWorker.DockerContainersManager do
  @moduledoc """
  Docker containers manager.

  A GenServer responsible for managing Docker containers on the local machine.
  Managing in this context means creating, starting, stopping and removing
  containers.

  TODO: which calls make sense to have async and which not.
  """

  use GenServer

  alias DockerEx.Containers

  def start_link(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  @doc """
  Create Docker container.

  ## Parameters

   * `name` - name of the created container
   * `image_name` - name of the image used by the container
   * `container_port` - port exposed from the container
   * `exposed_port` - port exposed by the Node

  ## Options

   * `env` - list of environment variables passed to the container
   * `host_ip` - IP address on which the container listens on. Default: 127.0.0.1
   * `timeout` - Overrides GenServer default timeout -- to handle longer Docker API response

  ## Examples

      iex> HivexWorker.DockerContainersManager.create_container("name", "fedora", "8080/tcp", "8080/tcp")
      {:ok,
       %{
         "Id" => "f7f0348d9566076684d01602f99f2826e3864045fceb94dd1b7e6f75d9c565cb",
         "Warnings" => []
       }}

  """
  def create_container(name, image_name, container_port, exposed_port, opts \\ []) do
    env = Keyword.get(opts, :env, [])
    host_ip = Keyword.get(opts, :host_ip, "127.0.0.1")
    timeout = Keyword.get(opts, :timeout, 30_000)

    create_body = %Containers.CreateContainer{
      Image: image_name,
      HostConfig: %{
        "PortBindings" => %{
          "#{container_port}/tcp" => [
            %{"HostIp" => host_ip, "HostPort" => "#{exposed_port}/tcp"}
          ]
        }
      },
      Env: env
    }

    GenServer.call(__MODULE__, {:create, [name: name, body: create_body]}, timeout)
  end

  @doc """
  Starts Docker container.

  ## Parameters

   * `container_id` - name or ID of the container

  ## Examples

      iex> HivexWorker.DockerContainersManager.start_container("name")
      {:ok, ""}
  """
  def start_container(container_id) do
    GenServer.call(__MODULE__, {:start, container_id})
  end

  @doc """
  Stop Docker container.

  TODO
  """
  def stop_container() do
    GenServer.call(__MODULE__, {:stop, "TODO"})
  end

  @doc """
  Deletes Docker container.

  ## Parameters

   * `container_id` - name or ID of the container

  ## Examples

      iex> HivexWorker.DockerContainersManager.start_container("name")
      {:ok, ""}
  """
  def delete_container(container_id, opts \\ []) do
    GenServer.call(__MODULE__, {:delete, container_id, opts})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:create, [name: name, body: create_body]}, _from, state) do
    case Containers.create_container(create_body, name: name) do
      {:ok, id} -> {:reply, {:ok, id}, state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_call({:start, container_id}, _from, state) do
    case Containers.start_container(container_id) do
      {:ok, id} -> {:reply, {:ok, id}, state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_call({:delete, container_id, opts}, _from, state) do
    case Containers.delete_container(container_id, opts) do
      {:ok, id} -> {:reply, {:ok, id}, state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end
end
