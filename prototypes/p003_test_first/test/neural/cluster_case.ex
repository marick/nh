defmodule ClusterCase do
  use AppAnimal
  alias AppAnimal.Neural
  alias Neural.Switchboard
  alias Neural.NetworkBuilder, as: Builder
  import ExUnit.Callbacks, only: [start_link_supervised!: 1]
  
  def switchboard_from_cluster_trace(clusters, keys \\ []) when is_list(clusters) do
    network = Builder.independent(clusters)
    keys
    |> Keyword.put_new(:network, network)
    |> switchboard()
  end

  def switchboard(keys) do
    with_defaults =
      keys 
      |> Keyword.put_new(:affordances, "test doesn't use affordances")
      |> Keyword.put_new(:network, "test doesn't use a network")
    
    state = struct(Switchboard, with_defaults)
    start_link_supervised!({Switchboard, state})
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
