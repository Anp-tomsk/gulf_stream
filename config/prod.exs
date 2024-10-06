import Config

config :gulf_stream,
  max_workers: System.get_env("MAX_WORKERS"),
  target_bytes: 10_000
