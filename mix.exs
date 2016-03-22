defmodule BaseHangul.Mixfile do
  use Mix.Project

  def project do
    [app: :basehangul,
     version: "0.1.0",
     elixir: "~> 1.2",
     description: "Elixir implementation of BaseHangul.",
     package: package,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:iconv]]
  end

  defp deps do
    [{:iconv, "~> 1.0"}]
  end

  defp package do
    [maintainers: ["Dalgona."],
     links: %{GitHub: "https://github.com/Dalgona/basehangul"},
     licenses: ["See GitHub page"]]
  end
end
