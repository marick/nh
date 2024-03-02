defmodule AppAnimal.Neural.LinearClusterTest do
  use ClusterCase, async: true
  
  describe "linear cluster handling: function version: basics" do 
    test "a transmission of pulses" do
      first = Cluster.linear(:first, fn pulse_data, configuration ->
        configuration.send_pulse_downstream.(carrying: pulse_data + 1)
      end)

      switchboard = from_trace([first, endpoint()])
    
      Switchboard.external_pulse(switchboard, to: :first, carrying: 1)
      assert_receive([2, from: :endpoint])
    end
  end
end
