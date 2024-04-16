alias AppAnimal.Cluster

defmodule Cluster.MakeTest do
  use ExUnit.Case, async: true
  use FlowAssertions
  alias Cluster.Make, as: UT
  alias AppAnimal.Duration
  alias Cluster.Throb

  describe "making circular clusters with circular" do 
    test "basic" do
      cluster = UT.circular(:example, & &1+1)

      assert_fields(cluster, name: :example,
                             label: :circular,
                             shape: Cluster.Shape.Circular.new)
      assert cluster.calc.(1) == 2
    end
    
    test "optional arguments go into the shape" do
      cluster = UT.circular(:example, & &1+1,
                            throb: Throb.counting_down_from(Duration.seconds(10)),
                            initial_value: [])

      assert cluster.shape.initial_value == []
      assert cluster.shape.throb.max_age == Duration.seconds(10)
      assert cluster.shape.throb.f_note_pulse == &Throb.pulse_does_nothing/2
    end
  end

  test "calc helpers" do
    assert UT.pulse("pulse data", "next state") == {:useful_result,    "pulse data", "next state"}
    assert UT.no_pulse("next state") ==            {:no_result,                      "next state"}
    assert UT.pulse_and_save("both") ==            {:useful_result,    "both",       "both"}
  end

  describe "specializations" do
    test "summarizer" do
      cluster = UT.summarizer(:example, &String.length/1)

      assert_fields(cluster, name: :example,
                             label: :summarizer,
                             shape: Cluster.Shape.Linear.new)
      
      assert cluster.calc.("long") == 4
    end

    test "gate" do
      cluster = UT.gate(:example, & &1 > 0)

      assert_fields(cluster, name: :example,
                             label: :gate,
                             shape: Cluster.Shape.Linear.new)
      
      assert cluster.calc.(0) == :no_result
      assert cluster.calc.(1) == 1
    end      
  end
end
