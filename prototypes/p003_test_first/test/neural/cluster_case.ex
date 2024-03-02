defmodule ClusterCase do
  use AppAnimal
  alias AppAnimal.Neural
  alias Neural.Switchboard
  alias Neural.NetworkBuilder, as: Builder
  alias Neural.ClusterMakers, as: Cluster
  import ExUnit.Callbacks, only: [start_link_supervised!: 1]
  
  def from_trace(clusters, keys \\ []) when is_list(clusters) do
    network = Builder.independent(clusters)
    keys
    |> Keyword.put_new(:network, network)
    |> switchboard()
  end

  def switchboard(keys) when is_list(keys) do
    with_defaults =
      keys 
      |> Keyword.put_new(:affordances, "test doesn't use affordances")
      |> Keyword.put_new(:network, "test doesn't use a network")
    
    state = struct(Switchboard, with_defaults)
    start_link_supervised!({Switchboard, state})
  end

  def mkfn__exit_to_test() do
    test_pid = self()
    fn data, %{name: name} ->
      send(test_pid, [data, from: name])
      :ok
    end
  end

  def endpoint(name \\ :endpoint) do
    Cluster.linear_cluster(name, mkfn__exit_to_test())
  end

  defmacro __using__(keys) do
    quote do
      use ExUnit.Case, unquote(keys)
      use AppAnimal
      alias AppAnimal.Neural
      alias Neural.Switchboard
      import Neural.ClusterMakers
      import ClusterCase
      use FlowAssertions
    end
  end
end
