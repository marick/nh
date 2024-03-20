defmodule ClusterCase do
  use AppAnimal
  alias AppAnimal.{Neural, Cluster}
  alias Cluster.{Shape, PulseLogic}
  alias ExUnit.Assertions

  defmacro assert_test_receives(value, keys \\ [from: :endpoint]) do
    quote do 
      [retval, from: _] = Assertions.assert_receive([unquote(value) | unquote(keys)])
      retval
    end
  end

  # The stripping out of `carrying` is a hack because of old behavior.
  def to_test(name \\ :endpoint) do
    filter =
      fn
        [carrying: pulse] -> pulse
        pulse -> pulse
      end
    
    %Cluster{name: name,
             label: :test_endpoint,
             shape: Shape.Linear.new,
             calc: filter,
             pulse_logic: PulseLogic.Test.new(name, self())
    }
  end

  def send_test_pulse(switchboard_pid, to: destination_name, carrying: pulse_data) do
    GenServer.cast(switchboard_pid,
                   {:distribute_pulse, carrying: pulse_data, to: [destination_name]})
  end
    

  defmacro __using__(keys) do
    quote do
      use ExUnit.Case, unquote(keys)
      use AppAnimal
      alias AppAnimal.Neural
      alias Neural.Switchboard
      alias Neural.AffordanceLand
      alias Neural.Network
      alias Neural.ActivityLogger
      import ClusterCase
      import AppAnimal.TraceAssertions
      use FlowAssertions
      import AffordanceLand, only: [response_to: 2, affords: 1]
      import Cluster.Make
    end
  end
end
