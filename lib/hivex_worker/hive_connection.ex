defmodule HivexWorker.HiveConnection do
  @moduledoc """
  Connection to the Hive -- to the Hivex application.
  """

  use Slipstream

  require Logger

  @topic_prefix "hive"

  def start_link(args) do
    Slipstream.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Slipstream
  def init(config) do
    Logger.debug(message: "Connecting to the Hive")
    connect(config)
  end

  @impl Slipstream
  def handle_connect(socket) do
    Logger.debug(message: "Joining topic")
    worker_id = Application.fetch_env!(:hivex_worker, :worker_id)
    {:ok, join(socket, "#{@topic_prefix}:#{worker_id}", %{})}
  end

  @impl Slipstream
  def handle_message(_topic, event, message, socket) do
    Logger.debug(
      message: "Got message from the Queen",
      event: event,
      message: message,
      socket: socket
    )

    {:ok, socket}
  end

  @impl Slipstream
  def handle_disconnect(:closed_by_remote = reason, socket) do
    # Shutdown the connection client upon disconnect from the server
    # Currently, the supervisor tries to restart the connection. After 3 failed attempts
    # the whole worker is shutdown -- this is good, because without queen the worker is useless
    # TODO: gracefull shutdown -- maybe?
    Logger.debug(
      message: "Connection to hive closed by the queen",
      reason: reason,
      socket: socket
    )

    {:stop, reason, socket}
  end

  @impl Slipstream
  def handle_disconnect(_reason, socket) do
    case reconnect(socket) do
      {:ok, socket} -> {:ok, socket}
      {:error, reason} -> {:stop, reason, socket}
    end
  end
end
