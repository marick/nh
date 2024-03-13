defmodule AppAnimal.Neural.LinearClusterTest do
  use ClusterCase, async: true

  def given(trace_or_network), do: AppAnimal.switchboard(trace_or_network)
  
  describe "linear cluster handling: function version: basics" do
    test "a transmission of pulses" do
      
      given([linear(:first, &(&1+1)), 
             to_test()])
      |> Switchboard.external_pulse(to: :first, carrying: 1)

      assert_test_receives(2)
    end
  end
end
