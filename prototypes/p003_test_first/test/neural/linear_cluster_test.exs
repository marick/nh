defmodule AppAnimal.Neural.LinearClusterTest do
  use ClusterCase, async: true
  
  describe "linear cluster handling: function version: basics" do 
    @tag :skip
    test "a single-cluster chain" do
      switchboard = switchboard_from([linear_cluster(:some_cluster, forward_pulse_to_test())])
      Switchboard.external_pulse(switchboard, to: :some_cluster, carrying: "pulse data")
      assert_receive("pulse data")
    end

    @tag :skip
    test "a transmission of pulses" do
    end
  end


  private do
    def forward_pulse_to_test do
      test_pid = self()
      fn pulse_data, _configuration ->
        send(test_pid, pulse_data)
        :ok
      end
    end
    
  end

end
