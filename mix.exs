defmodule HivexWorker.MixProject do
  use Mix.Project

  def project do
    [
      app: :hivex_worker,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {HivexWorker.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hivex_proxy_client, github: "revolko/hivex_proxy", subdir: "/hivex_proxy_client"}
    ]
  end
end
