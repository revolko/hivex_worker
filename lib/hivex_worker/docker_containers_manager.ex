defmodule HivexWorker.DockerContainersManager do
  @moduledoc """
  Docker containers manager.

  A GenServer responsible for managing Docker containers on the local machine.
  Managing in this context means creating, starting, stopping and removing
  containers.

  TODO: which calls make sense to have async and which not.
  """

  use GenServer

  def start_link(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  @doc """
  Create Docker container.

  TODO
  """
  def create_container() do
    GenServer.call(__MODULE__, {:create, "TODO"})
  end

  @doc """
  Start Docker container.

  TODO
  """
  def start_container() do
    GenServer.call(__MODULE__, {:start, "TODO"})
  end

  @doc """
  Stop Docker container.

  TODO
  """
  def stop_container() do
    GenServer.call(__MODULE__, {:stop, "TODO"})
  end

  @doc """
  Remove Docker container.

  TODO
  """
  def remove_container() do
    GenServer.call(__MODULE__, {:remove, "TODO"})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(request, _from, state) do
    {:reply, request, state}
  end

  @impl true
  def handle_cast(_request, state) do
    {:noreply, state}
  end
end
