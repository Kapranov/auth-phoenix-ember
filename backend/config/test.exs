use Mix.Config

config :backend, BackendWeb.Endpoint,
  http: [port: 4001],
  server: false

config :logger, level: :warn

import_config "test.secret.exs"
