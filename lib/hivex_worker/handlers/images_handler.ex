defmodule HivexWorker.Handlers.ImagesHandler do
  @moduledoc """
  GenServer handling images
  """

  require Logger

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(default_state) do
    {:ok, default_state}
  end

  @impl true
  def handle_cast(
        {"build_image", %{"name" => name, "remote_url" => remote_url, "tag" => tag} = image},
        state
      ) do
    Logger.info(
      message: "Building image",
      image: image
    )

    with {:ok, _image} <- DockerEx.Images.build_image(remote_url, name, tag: tag) do
      Logger.info(
        message: "Image built successfully",
        image: image
      )

      # TODO: notify queen about success

      {:noreply, state}
    else
      {:error, reason} ->
        Logger.error(
          message: "Failed to build the image",
          reason: reason
        )

        # TODO: notify queen about failure
        {:noreply, state}
    end
  end

  @impl true
  def handle_cast({"pull_image", %{"name" => name, "tag" => tag} = image}, state) do
    Logger.info(
      message: "Pulling image",
      image: image
    )

    with {:ok, _image} <- DockerEx.Images.create_image(name, tag: tag) do
      Logger.info(
        message: "Image pulled successfully",
        image: image
      )

      # TODO: notify queen about success

      {:noreply, state}
    else
      {:error, reason} ->
        Logger.error(
          message: "Failed to build the image",
          reason: reason
        )

        # TODO: notify queen about failure
        {:noreply, state}
    end
  end
end
