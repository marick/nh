defmodule AppAnimal.Neural.CircularClusterTest do
  use ClusterCase, async: true
  
  describe "circular cluster handling: function version: basics" do 
    test "a single-cluster chain" do
      switchboard = from_trace([Cluster.circular(:some_cluster, forward_pulse_to_test())])
      Switchboard.external_pulse(switchboard, to: :some_cluster, carrying: "pulse data")
      assert_receive("pulse data")
    end

    test "a transmission of pulses" do
      handle_pulse = fn pulse_data, _mutable, configuration ->
        configuration.send_pulse_downstream.(carrying: pulse_data + 1)
        :there_is_no_mutable_state_to_affect
      end

      first = Cluster.circular(:first, handle_pulse)
      second = Cluster.circular(:second, forward_pulse_to_test())
      switchboard = from_trace([first, second])
    
      Switchboard.external_pulse(switchboard, to: :first, carrying: 1)
      assert_receive(2)
    end
  end

  describe "longevity of circular clusters" do 
    def initialize_with_empty_pids do
      fn _configuration -> %{pids: []} end
    end
    
    def pulse_accumulated_pids() do
      fn :nothing, mutable, configuration ->
        mutated = update_in(mutable.pids, &([self() | &1]))
        configuration.send_pulse_downstream.(carrying: mutated.pids)
        mutated
      end
    end
    
    test "succeeding pulses go to the same process" do
      first = Cluster.circular(:first,
                               pulse_accumulated_pids(),
                               initialize_mutable: initialize_with_empty_pids())
      second = Cluster.circular(:second, forward_pulse_to_test())
      switchboard = from_trace([first, second])
      
      Switchboard.external_pulse(switchboard, to: :first, carrying: :nothing)
      [first_pid] = assert_receive(_)
      
      Switchboard.external_pulse(switchboard, to: :first, carrying: :nothing)
      assert_receive([^first_pid, ^first_pid])
    end
    
    test "... however, processes 'age out'" do
      first = Cluster.circular(:first,
                               pulse_accumulated_pids(),
                               initialize_mutable: initialize_with_empty_pids(),
                               starting_pulses: 2)
      second = Cluster.circular(:second, forward_pulse_to_test())
      switchboard = from_trace([first, second], pulse_rate: 1)
      
      Switchboard.external_pulse(switchboard, to: :first, carrying: :nothing)
      [first_pid] = assert_receive(_)
      
      Process.sleep(30)
      Switchboard.external_pulse(switchboard, to: :first, carrying: :nothing)
      
      [second_pid] = assert_receive(_)
      refute second_pid == first_pid
    end
  end
  
  defmodule ModuleVersion do
    def initialize do
    end
    
    def handle_pulse do
    end
  end

  describe "a circular cluster as a module" do
    @tag :skip
    test "a single-cluster chain" do
      # switchboard = from_trace([Cluster.circular(:some_cluster, ModuleVersion)])
      # Switchboard.external_pulse(to: :some_cluster, carrying: "pulse data", via: switchboard)
      # assert_receive("pulse data")
    end
  end

  private do
    def forward_pulse_to_test do
      test_pid = self()
      fn pulse_data, mutable, _configuration ->
        send(test_pid, pulse_data)
        mutable
      end
    end
  end
end
