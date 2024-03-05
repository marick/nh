defmodule AppAnimal.Neural.LinearClusterTest do
  use ClusterCase, async: true

  def given(trace_or_network), do: AppAnimal.switchboard(trace_or_network)
  
  describe "linear cluster handling: function version: basics" do
    test "a transmission of pulses" do
      
      given([Cluster.linear(:first, calc: &(&1+1)), 
             endpoint()])
      |> Switchboard.external_pulse(to: :first, carrying: 1)

      assert_test_receives(2)
    end
  end
end
