defmodule Warren.Mixfile do
  use Mix.Project

  def project do
    [app: :warren,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     source_url: "https://github.com/CityBaseInc/warren",
     description: "Routing DSL for consuming AMQP messages",
     package: package()]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE*"],
      maintainers: ["Alex Pedenko"],
      organization: "CityBase, Inc",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/CityBaseInc/warren"}
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:amqp, "~> 1.0.0-pre.2"},
     {:ex_doc, ">= 0.0.0", only: :dev}]
  end
end
