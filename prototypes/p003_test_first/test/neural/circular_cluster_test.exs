defmodule AppAnimal.Neural.CircularClusterTest do
  use ClusterCase, async: true

  def given(trace_or_network), do: AppAnimal.switchboard(trace_or_network)

  describe "circular cluster handling: function version: basics" do 
    test "a transmission of pulses" do

      given([circular(:first,
                      one_pulse(after: & &1 + 1)),
             to_test()])
      |> Switchboard.external_pulse(to: :first, carrying: 1)
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
      switchboard_pid = 
        given([circular(:first,
                        empty_pids(),
                        one_pulse(after: accumulate_pids())),
               to_test()])
      
      Switchboard.external_pulse(switchboard_pid, to: :first, carrying: :nothing)
      assert_test_receives([first_pid])
      
      Switchboard.external_pulse(switchboard_pid, to: :first, carrying: :nothing)
      assert_test_receives([^first_pid, ^first_pid])
      
      # asynchrony, just for fun
      Switchboard.external_pulse(switchboard_pid, to: :first, carrying: :nothing)
      Switchboard.external_pulse(switchboard_pid, to: :first, carrying: :nothing)
      assert_test_receives([^first_pid, ^first_pid, ^first_pid, ^first_pid])
    end

    test "... however, processes 'age out'" do
      switchboard_pid =
        [circular(:first,
                  empty_pids(),
                  one_pulse(after: accumulate_pids()),
                  starting_pulses: 2),
         to_test()]
        |> AppAnimal.switchboard(pulse_rate: 1)
      
      Switchboard.external_pulse(switchboard_pid, to: :first, carrying: :nothing)
      assert_test_receives([first_pid])
      
      Process.sleep(30)
      Switchboard.external_pulse(switchboard_pid, to: :first, carrying: :nothing)
      
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
        if mutated.count >= 0 do
          Cluster.Variations.Propagation.send_pulse(configuration.propagate, carrying: mutated.pids)
        end
        mutated
      end
    
    first = circular(:first,
                     fn _configuration -> %{pids: [], count: 3} end,
                     calc)

    network = 
      Network.trace([first, first])
      |> Network.extend(at: :first, with: [to_test()])

    given(network)
    |> Switchboard.external_pulse(to: :first, carrying: :nothing)

    assert_test_receives([pid])
    assert_test_receives([^pid, ^pid])
    assert_test_receives([^pid, ^pid, ^pid])
  end
end
