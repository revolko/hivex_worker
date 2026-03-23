defmodule HivexWorker.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HivexWorker.DockerContainersManager
    ]

    opts = [strategy: :one_for_one, name: HivexWorker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
