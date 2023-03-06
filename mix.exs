defmodule MainProxy.MixProject do
  use Mix.Project

  def project do
    [
      app: :main_proxy,
      version: "0.2.0",
      description:
        "Proxies requests to multiple apps. Useful for Gigalixir or Heroku deployment when just one web port is exposed. Works with phoenix endpoints, plugs, and websockets.",
      package: package(),
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/Main-Proxy/main_proxy",
      homepage_url: "https://github.com/Main-Proxy/main_proxy"
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package() do
    [
      name: "main_proxy",
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Jason Axelson", "Jesse Shieh"],
      licenses: ["MIT"],
      links: %{GitHub: "https://github.com/Main-Proxy/main_proxy"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, ">= 2.6.0"},
      {:phoenix, "~> 1.7"},

      # for hex.pm
      {:ex_doc, ">= 0.0.0", only: :dev},

      # test
      {:stream_data, "~> 0.4", only: [:dev, :test]},
      {:jason, "~> 1.0", only: :test}
    ]
  end
end
