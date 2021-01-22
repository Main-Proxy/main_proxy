defmodule MasterProxy.MixProject do
  use Mix.Project

  def project do
    [
      app: :master_proxy,
      version: "0.1.3",
      description:
        "Proxies requests to multiple apps. Useful for Gigalixir or Heroku deployment when just one web port is exposed. Works with phoenix endpoints, plugs, and websockets.",
      package: package(),
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(:ci), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_), do: ["lib", "web"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package() do
    [
      name: "master_proxy",
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Jesse Shieh"],
      licenses: ["MIT"],
      links: %{GitHub: "https://github.com/jesseshieh/master_proxy"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:phoenix, "~> 1.4"},

      # for hex.pm
      {:ex_doc, ">= 0.0.0", only: :dev},

      # test
      {:stream_data, "~> 0.4", only: :test},
      {:jason, "~> 1.0", only: :test},
      {:websocket_client, git: "https://github.com/jeremyong/websocket_client.git", only: :test}
    ]
  end
end
