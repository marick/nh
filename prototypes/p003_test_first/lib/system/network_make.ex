alias AppAnimal.System
alias AppAnimal.System.Network

defmodule Network.Make do
  @moduledoc """
  Functions for, first, creating a `Network` and, next, linking all the
  clusters in the network into the larger `AppAnimal`, which will then
  `enliven` them.
  """
  use AppAnimal
  alias System.{AffordanceLand, Switchboard}
  
  def trace(network \\ %Network{}, clusters) do
    old = network.clusters_by_name
    new = 
      add_only_new_clusters(old, clusters)
      |> add_downstream(Enum.chunk_every(clusters, 2, 1, :discard))
    %{network | clusters_by_name: new}
  end

  def extend(network, at: name, with: trace) do
    existing = deeply_get_only(network, Network.l_cluster_named(name))
    trace(network, [existing | trace])
  end

  def link_clusters_to_architecture(network,  %System.Router{} = router, _p_switchboard, _p_affordances) do
    mkfn_final =
      fn so_far ->
        case so_far do
          {Switchboard, _f_maker} ->
            &Function.identity/1
          {AffordanceLand, _f_maker} ->
            &Function.identity/1
          already_made when is_function(already_made, 1) ->
            already_made
        end
      end

    l_f_outward = Network.l_clusters() |> Cluster.l_f_outward()
    l_router = Network.l_clusters() |> Cluster.l_router()
    
    deeply_map(network, l_f_outward, mkfn_final)
    |> deeply_put(l_router, router)
  end

  IO.puts "#{__ENV__.file} remove l_f_outward and mkfn_functions"



  private do 
    # I don't use lenses for this because it's too fiddly and non-obvious
    # how getting the priority right works.
    def add_only_new_clusters(network, trace) when is_list trace do
      Enum.reduce(trace, network, fn cluster, acc ->
        Map.put_new(acc, cluster.name, cluster)
      end)
    end
    
    def add_downstream(network, []), do: network
    
    def add_downstream(network, [[upstream, downstream] | rest]) do
      network
      |> update_in([upstream.name, Access.key(:downstream)], &([downstream.name | &1]))
      |> add_downstream(rest)
    end
  end
end
