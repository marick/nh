defmodule ClusterCase do
  use AppAnimal
  alias AppAnimal.Neural
  alias Neural.Switchboard
  alias Neural.NetworkBuilder, as: Builder
  alias Neural.Cluster
  import ExUnit.Callbacks, only: [start_link_supervised!: 1]
  require ExUnit.Assertions
  
  def from_trace(clusters, keys \\ []) when is_list(clusters) do
    network = Builder.independent(clusters)
    keys
    |> Keyword.put_new(:network, network)
    |> switchboard()
  end

  def world_connected_to(switchboard) do
    start_link_supervised!({Neural.AffordanceLand, switchboard: switchboard})
  end

  def affordance_from!(affordance_source, [{name, data}]) do
    Neural.AffordanceLand.provide_affordance(affordance_source,
                                             named: name, conveying: data)
  end

  def switchboard(keys) when is_list(keys) do
    with_defaults =
      keys 
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

  defmacro assert_test_receives(value, keys \\ [from: :endpoint]) do
    quote do 
      [retval, from: _] = ExUnit.Assertions.assert_receive([unquote(value) | unquote(keys)])
      retval
    end
  end

  def endpoint(name \\ :endpoint) do
    Cluster.linear(name, mkfn__exit_to_test())
  end

  defmacro __using__(keys) do
    quote do
      use ExUnit.Case, unquote(keys)
      use AppAnimal
      alias AppAnimal.Neural
      alias Neural.Switchboard
      alias Neural.NetworkBuilder, as: Builder
      alias Neural.Cluster
      import ClusterCase
      use FlowAssertions
    end
  end
end
