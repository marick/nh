alias AppAnimal.Cluster

defmodule Cluster.MakeTest do
  use ExUnit.Case, async: true
  use FlowAssertions
  alias Cluster.Make, as: UT

  describe "making circular clusters with circular2" do 
    test "basic" do
      cluster = UT.circular2(:example, & &1+1)

      |> assert_fields(name: :example,
                       label: :circular_cluster,
                       shape: Cluster.Shape.Circular.new,
                       pulse_logic: Cluster.PulseLogic.Internal.new(from_name: :example)
      )

      assert cluster.calc.(1) == 2
      end
    
    test "optional arguments go into the shape" do
      cluster = UT.circular2(:example, & &1+1, starting_pulses: 1000,
                                               initial_value: [])


      cluster.shape
      |> assert_fields(starting_pulses: 1000, initial_value: [])
    end
  end
  
end
