alias AppAnimal.ClusterBuilders

defmodule ClusterBuilders do
  use AppAnimal
  alias Cluster.Throb

  def circular(name, calc, opts) when is_function(calc) and is_list(opts) do
    opts
    |> Opts.rename(:initial_value, to: :previously)
    |> Opts.add_missing!(name: name, calc: calc)
    |> Opts.add_missing!(id: Cluster.Identification.new(name, :circular))
    |> Opts.add_if_missing(label: :circular,
                           throb: Throb.default,
                           previously: %{})
    |> Opts.add_missing!(router: :must_be_supplied_later)
    |> then(& struct(Cluster.Circular, &1))

  end

  def circular(name, calc     ) when is_function(calc),
      do: circular(name, calc, [])
  def circular(name,      opts) when is_list(opts),
      do: circular(name, &Function.identity/1, opts)

  def circular(name), do: circular(name, [])

  ##

  def linear(name, calc, opts) when is_function(calc) and is_list(opts) do
    opts
    |> Opts.add_missing!(name: name, calc: calc)
    |> Opts.create(       :id, if_present: :label,
                               with: & Cluster.Identification.new(name, &1))
    |> Opts.add_if_missing(id: Cluster.Identification.new(name, :linear))

    |> then(& struct(Cluster.Linear, &1))
  end

  def linear(name, calc) when is_function(calc),
      do: linear(name, calc, [])

  def linear(name, opts) when is_list(opts),
      do: linear(name, &Function.identity/1, opts)

  def linear(name), do: linear(name, &Function.identity/1)

end
