import Config

config :gulf_stream,
  max_workers: 4,
  target_bytes: 10_000

import_config "#{config_env()}.exs"
