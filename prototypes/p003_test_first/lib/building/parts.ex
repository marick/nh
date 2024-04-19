alias AppAnimal.{Building,Cluster}

defmodule Building.Parts do
  use AppAnimal
  alias Cluster.Throb
  
  def circular(name, calc, opts) when is_function(calc) and is_list(opts) do
    opts =
      opts
      |> Opts.add_missing!(name: name, calc: calc)
      |> Opts.add_missing!(id: Cluster.Identification.new(name, :circular))
      |> Opts.add_if_missing(label: :circular,
                             throb: Throb.default,
                             previously: %{})
      |> Opts.add_missing!(router: :must_be_supplied_later)

    
    struct(Cluster.Circular, opts)
  end

  def circular(name, calc     ) when is_function(calc),
      do: circular(name, calc, [])
  def circular(name,      opts) when is_list(opts),
      do: circular(name, &Function.identity/1, opts)

  def circular(name), do: circular(name, [])
end
