defmodule AppAnimal.Neural.LinearClusterTest do
  use ClusterCase, async: true
  
  describe "linear cluster handling: function version: basics" do
    test "a transmission of pulses" do
      first = Cluster.linear(:first, calc: &(&1+1))
      switchboard = from_trace([first, endpoint()])
    
      Switchboard.external_pulse(switchboard, to: :first, carrying: 1)
      assert_test_receives(2)
    end
  end
end
