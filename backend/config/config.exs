use Mix.Config

config :backend,
  ecto_repos: [Backend.Repo]

config :backend, BackendWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "eLGbT1CAcdSNLk/ajdHwlNIXa5Cl8inLDeLa4K2MqRZ82yEL1nGf8ha8u/4U8OIg",
  render_errors: [view: BackendWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Backend.PubSub,
           adapter: Phoenix.PubSub.PG2]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

import_config "#{Mix.env}.exs"
