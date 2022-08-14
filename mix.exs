defmodule XunitFormatter.MixProject do
  use Mix.Project

  def project do
    [
      app: :xunit_formatter,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      name: "ExUnit XUnit Formatter",
      source_url: "https://github.com/veedo/xunit_formatter"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:xml_builder, "~> 2.2"},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
    ]
  end

  defp package do
    [
      name: "exunit_formatter_xunit",
      description: "XUnit Formatter for exunit test results. The format is tailored to work with azure devops, but any XUnit parser will work.",
      licenses: ["MIT"],
      maintainers: ["Zander Erasmus"],
      links: %{GitHub: "https://github.com/veedo/xunit_formatter"}
    ]
  end

  defp docs do
    [main: "readme", extras: ["README.md"]]
  end
end
