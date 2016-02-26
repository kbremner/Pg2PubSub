defmodule Pg2pubsub.Mixfile do
  use Mix.Project

  def project do
    [app: :pg2pubsub,
     version: version,
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description,
     package: package,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:ex_doc, "~> 0.11", only: [:dev]}]
  end

  defp description do
    """
    A PubSub implementation for Elixir, using PG2 (Erlang process groups).
    """
  end

  defp package do
    [# These are the default files included in the package
     files: ["lib", "mix.exs", "README*", "LICENSE*"],
     maintainers: ["Kyle Bremner"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/kbremner/pg2pubsub",
      "Builds" => "https://semaphoreci.com/kbremner/pg2pubsub"}]
  end

  defp version do
    ver = System.get_env("version")
    if ver == nil do
      ver = "0.0.1"
    end
    ver
  end
end
