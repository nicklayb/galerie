defmodule Galerie.MixProject do
  use Mix.Project

  def project do
    [
      app: :galerie,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      releases: releases(),
      test_coverage: [
        ignore_modules: [
          GalerieWeb,
          GalerieWeb.ConnCase,
          GalerieWeb.Endpoint,
          GalerieWeb.Gettext,
          GalerieWeb.Telemetry,
          Galerie.Application,
          Galerie.DataCase,
          Galerie.BaseCase,
          ~r/^GalerieTest\.(.*)/,
          ~r/^Swoosh\.(.*)/
        ]
      ]
    ]
  end

  def application do
    [
      mod: {Galerie.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(env) when env in ~w(test dev)a, do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:argon2_elixir, "~> 4.0"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ecto_sql, "~> 3.7"},
      {:esbuild, "~> 0.2", runtime: Mix.env() == :dev},
      {:file_system, "~> 0.0"},
      {:floki, ">= 0.36.0", only: :test},
      {:gettext, "~> 0.11"},
      {:gen_smtp, "~> 1.0"},
      {:hackney, "~> 1.18"},
      {:image, "~> 0.37"},
      {:exif_parser, "~> 0.3"},
      {:jason, "~> 1.1"},
      {:oban, "~> 2.16"},
      {:phoenix, "~> 1.7.9"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_live_view, "~> 0.20.17"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.4.1", only: :dev},
      {:phoenix_live_dashboard, "~> 0.8.2"},
      {:phoenix_pubsub, "~> 2.0"},
      {:plug_cowboy, "~> 2.5"},
      {:postgrex, "~> 0.16"},
      {:sentry, "~> 8.0"},
      {:swoosh, "~> 1.14.2"},
      {:sweet_xml, "~> 0.6"},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "ecto.setup"],
      "assets.deploy": [
        "esbuild default --minify",
        "tailwind default",
        "assets.copy",
        "phx.digest"
      ],
      "assets.copy": ["cmd mix assets.copy"],
      "assets.copy": "cmd --cd assets npm run copy-static",
      "assets.setup": [
        "deps.get",
        "tailwind.install",
        "esbuild.install",
        "cmd npm install --prefix assets"
      ],
      "ecto.setup": ["ecto.create", "ecto.migrate", "ecto.seed"],
      "ecto.seed": ["run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end

  defp releases do
    [
      galerie: [
        include_executables_for: [:unix],
        applications: [
          galerie: :permanent
        ]
      ]
    ]
  end
end
