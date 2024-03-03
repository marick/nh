defmodule AppAnimal.Neural.CircularClusterTest do
  use ClusterCase, async: true

  describe "circular cluster handling: function version: basics" do 
    test "a transmission of pulses" do
      first = Cluster.circular(:first, Cluster.one_pulse(after: & &1 + 1))
      switchboard = from_trace([first, endpoint()])
    
      Switchboard.external_pulse(switchboard, to: :first, carrying: 1)
      assert_test_receives(2)
    end
  end
  
  describe "longevity of circular clusters" do 
    def empty_pids, do: constantly(%{pids: []})
    
    def accumulate_pids() do
      fn _, mutable ->
        mutated = update_in(mutable.pids, & [self() | &1])
        {mutated.pids, mutated}
      end
    end
    
    test "succeeding pulses go to the same process" do
      first = Cluster.circular(:first,
                               empty_pids(),
                               Cluster.one_pulse(after: accumulate_pids()))
      switchboard = from_trace([first, endpoint()])
      
      Switchboard.external_pulse(switchboard, to: :first, carrying: :nothing)
      assert_test_receives([first_pid])
      
      Switchboard.external_pulse(switchboard, to: :first, carrying: :nothing)
      assert_test_receives([^first_pid, ^first_pid])

      # asynchrony, just for fun
      Switchboard.external_pulse(switchboard, to: :first, carrying: :nothing)
      Switchboard.external_pulse(switchboard, to: :first, carrying: :nothing)
      assert_test_receives([^first_pid, ^first_pid, ^first_pid, ^first_pid])
      
    end

    test "... however, processes 'age out'" do
      first = Cluster.circular(:first,
                               empty_pids(),
                               Cluster.one_pulse(after: accumulate_pids()),
                               starting_pulses: 2)
      switchboard = from_trace([first, endpoint()], pulse_rate: 1)
      
      Switchboard.external_pulse(switchboard, to: :first, carrying: :nothing)
      assert_test_receives([first_pid])
      
      Process.sleep(30)
      Switchboard.external_pulse(switchboard, to: :first, carrying: :nothing)
      
      assert_test_receives([second_pid])
      refute second_pid == first_pid
    end
  end


  test "a circular trace" do
    calc = 
      fn _, mutable, configuration ->
        mutated = 
          %{mutable | pids: [self() | mutable.pids],
                      count: mutable.count - 1}
        if mutated.count >= 0,
           do: configuration.send_pulse_downstream.(carrying: mutated.pids)
        mutated
      end
    
    first = Cluster.circular(:first,
                             fn _configuration -> %{pids: [], count: 3} end,
                             calc)
    
    network =
      Builder.independent([first, first])
      |>  Builder.extend(at: :first, with: [endpoint()])
    switchboard = switchboard(network: network)
    Switchboard.external_pulse(switchboard, to: :first, carrying: :nothing)
    assert_test_receives([pid])
    assert_test_receives([^pid, ^pid])
    assert_test_receives([^pid, ^pid, ^pid])
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
end
