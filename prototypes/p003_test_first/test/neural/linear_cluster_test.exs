defmodule AppAnimal.Neural.LinearClusterTest do
  use ClusterCase, async: true
  
  describe "linear cluster handling: function version: basics" do 
    test "a single-cluster chain" do
      switchboard = switchboard_from([linear_cluster(:final_cluster, forward_pulse_to_test())])
      Switchboard.external_pulse(switchboard, to: :final_cluster, carrying: "pulse data")
      assert_receive({:final_cluster, "pulse data"})
    end

    @tag :skip
    test "a transmission of pulses" do
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
