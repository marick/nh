defmodule AppAnimal.MixProject do
  use Mix.Project

  def project do
    [
      app: :app_animal,
      version: "0.1.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]
  

  # Run "mix help deps" to learn about dependencies.
  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:private, "> 0.0.0"},
      {:flow_assertions, "~> 0.6", only: :test},
      {:shorter_maps, "~> 2.2"},
      {:iteraptor, "~> 1.14"},
      {:circular_buffer, "~> 0.4"},
      {:typedstruct, "~> 0.5.2"},
      {:typed_struct_lens, "~> 0.1.1"},
      
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
    
  end
end
