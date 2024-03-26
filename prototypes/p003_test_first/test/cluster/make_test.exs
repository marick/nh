alias AppAnimal.Cluster

defmodule Cluster.MakeTest do
  use ExUnit.Case, async: true
  use FlowAssertions
  alias Cluster.Make, as: UT
  import AppAnimal.System.Network.Throbbing, only: [seconds: 1]

  describe "making circular clusters with circular" do 
    test "basic" do
      cluster = UT.circular(:example, & &1+1)

      |> assert_fields(name: :example,
                       label: :circular_cluster,
                       shape: Cluster.Shape.Circular.new)
                       
      assert cluster.calc.(1) == 2
      end
    
    test "optional arguments go into the shape" do
      cluster = UT.circular(:example, & &1+1, starting_lifespan: seconds(10),
                                              initial_value: [])


      cluster.shape
      |> assert_fields(starting_lifespan: seconds(10), initial_value: [])
    end
  end

  test "calc helpers" do
    assert UT.pulse("pulse data", "next state") == {:pulse,    "pulse data", "next state"}
    assert UT.no_pulse("next state") ==            {:no_pulse,               "next state"}
    assert UT.pulse_and_save("both") ==            {:pulse,    "both",       "both"}
  end

  describe "specializations" do
    test "summarizer" do
      cluster = UT.summarizer(:example, &String.length/1)

      |> assert_fields(name: :example,
                       label: :summarizer,
                       shape: Cluster.Shape.Linear.new)
                       
      assert cluster.calc.("long") == 4
    end

    test "gate" do
      cluster = UT.gate(:example, & &1 > 0)

      |> assert_fields(name: :example,
                       label: :gate,
                       shape: Cluster.Shape.Linear.new)
                       
      assert cluster.calc.(0) == :no_pulse
      assert cluster.calc.(1) == 1
    end      
    
  end
end
