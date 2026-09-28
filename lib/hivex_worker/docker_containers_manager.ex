defmodule HivexWorker.DockerContainersManager do
  @moduledoc """
  Docker containers manager.
  """

  alias DockerEx.Containers

  @doc """
  Creates Docker container.

  ## Parameters

   * `name` - name of the created container
   * `image_name` - name of the image used by the container
   * `container_port` - port exposed from the container
   * `exposed_port` - port exposed by the Node

  ## Options

   * `env` - list of environment variables passed to the container
   * `host_ip` - IP address on which the container listens on. Default: 127.0.0.1

  ## Examples

      iex> HivexWorker.DockerContainersManager.create_container("name", "fedora", 8080, 8080)
      {:ok,
       %{
         "Id" => "f7f0348d9566076684d01602f99f2826e3864045fceb94dd1b7e6f75d9c565cb",
         "Warnings" => []
       }}

  """
  def create_container(name, image_name, container_port, exposed_port, opts \\ []) do
    env = Keyword.get(opts, :env, [])
    host_ip = Keyword.get(opts, :host_ip, "127.0.0.1")

    create_body = %Containers.CreateContainer{
      Image: image_name,
      HostConfig: %{
        "PortBindings" => %{
          "#{container_port}" => [
            %{"HostIp" => host_ip, "HostPort" => "#{exposed_port}"}
          ]
        }
      },
      Env: env
    }

    Containers.create_container(create_body, name: name)
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
    Containers.start_container(container_id)
  end

  @doc """
  Deletes Docker container.

  ## Parameters

   * `container_id` - name or ID of the container

  ## Examples

      iex> HivexWorker.DockerContainersManager.delete_container("name")
      {:ok, ""}
  """
  def delete_container(container_id, opts \\ []) do
    Containers.delete_container(container_id, opts)
  end

  @doc """
  Inspects given container and returns its ID.

  ## Parameters

   * `name` - name or ID of the container


  ## Examples

      iex> HivexWorker.DockerContainersManager.get_container_id("name")
      {:ok, "the docker ID"}
  """
  def get_container_id(name) do
    case Containers.inspect_container(name) do
      {:ok, container_map} -> {:ok, Map.get(container_map, "Id")}
      error -> error
    end
  end
end
