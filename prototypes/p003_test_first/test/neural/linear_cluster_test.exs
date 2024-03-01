defmodule AppAnimal.Neural.LinearClusterTest do
  use ClusterCase, async: true
  
  describe "linear cluster handling: function version: basics" do 
    test "a single-cluster chain" do
      switchboard = switchboard_from_cluster_trace([linear_cluster(:final_cluster, forward_pulse_to_test())])
      Switchboard.external_pulse(switchboard, to: :final_cluster, carrying: "pulse data")
      assert_receive({:final_cluster, "pulse data"})
    end

    test "a transmission of pulses" do
      handle_pulse = fn pulse_data, configuration ->
        configuration.send_pulse_downstream.(carrying: pulse_data + 1)
      end

      first = linear_cluster(:first, handle_pulse)
      second = linear_cluster(:second, forward_pulse_to_test())
      switchboard = switchboard_from_cluster_trace([first, second])
    
      Switchboard.external_pulse(switchboard, to: :first, carrying: 1)
      assert_receive({:second, 2})
    end
  end


  private do
    def forward_pulse_to_test do
      test_pid = self()
      fn pulse_data, %{name: name} ->
        send(test_pid, {name, pulse_data})
        :ok
      end
    end
    
  end

end
