defmodule Daat.MixProject do
  use Mix.Project

  def project do
    [
      app: :daat,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "Daat",
      docs: docs(),

      # Hex
      description: "Parameterized modules for Elixir",
      package: package()
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_url: "https://github.com/quinnwilton/daat"
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/quinnwilton/daat"},
      maintainers: ["Quinn Wilton"]
    ]
  end
end
