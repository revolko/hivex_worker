import Config

config :hivex_worker,
  queen_hostname: System.get_env("HIVEX_WORKER_QUEEN_HOSTNAME", "ws://localhost"),
  queen_port: System.get_env("HIVEX_WORKER_QUEEN_PORT", "4000"),
  worker_id: System.fetch_env!("HIVEX_WORKER_ID"),
  worker_key: System.fetch_env!("HIVEX_WORKER_KEY")
