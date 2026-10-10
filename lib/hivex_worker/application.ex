defmodule HivexWorker.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    queen_hostname = Application.fetch_env!(:hivex_worker, :queen_hostname)
    queen_port = Application.fetch_env!(:hivex_worker, :queen_port)
    worker_id = Application.fetch_env!(:hivex_worker, :worker_id)
    worker_key = Application.fetch_env!(:hivex_worker, :worker_key) |> Base.encode64()

    children = [
      HivexWorker.DockerContainersManager,
      HivexWorker.Handler,
      {HivexWorker.HiveConnection,
       uri:
         "#{queen_hostname}:#{queen_port}/socket/websocket?" <>
           URI.encode_query(%{"worker_id" => worker_id}),
       headers: [
         {"Sec-WebSocket-Protocol", "phoenix, base64url.bearer.phx.#{worker_key}"}
       ]}
    ]

    opts = [strategy: :one_for_one, name: HivexWorker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
