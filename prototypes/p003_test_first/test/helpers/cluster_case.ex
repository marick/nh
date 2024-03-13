defmodule ClusterCase do
  use AppAnimal
  alias AppAnimal.Neural
  alias Cluster.Base
  alias Cluster.Variations.{Topology, Propagation}
  alias ExUnit.Assertions

  defmacro assert_test_receives(value, keys \\ [from: :endpoint]) do
    quote do 
      [retval, from: _] = Assertions.assert_receive([unquote(value) | unquote(keys)])
      retval
    end
  end

  # The stripping out of `carrying` is a hack because of old behavior.
  def to_test(name \\ :endpoint) do
    handler =
      fn
        [carrying: pulse], cluster -> 
          Propagation.send_pulse(cluster.propagate, pulse)
        pulse, cluster ->
          Propagation.send_pulse(cluster.propagate, pulse)
      end
    
    %Base{name: name,
          label: :test_endpoint,
          topology: Topology.Linear.new,
          propagate: Propagation.Test.new(name, self()),
          handlers: %{handle_pulse: handler}
  }
  end

  defmacro __using__(keys) do
    quote do
      use ExUnit.Case, unquote(keys)
      use AppAnimal
      alias AppAnimal.Neural
      alias Neural.Switchboard
      alias Neural.Affordances
      alias Neural.Network
      alias Neural.ActivityLogger
      import ClusterCase
      import AppAnimal.TraceAssertions
      use FlowAssertions
      import Affordances, only: [response_to: 2, affords: 1]
      import Cluster.Make
    end
  end
end
