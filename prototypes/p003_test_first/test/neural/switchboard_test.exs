defmodule AppAnimal.Neural.SwitchboardTest do
  use ExUnit.Case, async: true
  alias AppAnimal.Neural
  alias Neural.Switchboard, as: UT
  # import FlowAssertions.TabularA
  alias Neural.NetworkBuilder, as: N
  import Neural.ClusterMakers
  

  def pulse_to_test do
    test_pid = self()
    fn pulse_data, _configuration, mutable ->
      send(test_pid, pulse_data)
      mutable
    end
  end

  def switchboard_from(clusters) when is_list(clusters) do
    network = N.start(clusters)
    state = %UT{environment: "irrelevant", network: network}
    start_link_supervised!({UT, state})
  end

  describe "circular cluster handling" do 
    test "a single-cluster chain" do
      switchboard = switchboard_from([circular_cluster(:some_cluster, pulse_to_test())])
      UT.initial_pulse(to: :some_cluster, carrying: "pulse data", via: switchboard)
      assert_receive("pulse data")
    end

    test "a transmission of pulses" do
      handle_pulse = fn pulse_data, configuration, mutable ->
        configuration.send_pulse_downstream.(carrying: pulse_data + 1)
        mutable
      end

      first = circular_cluster(:first, handle_pulse)
      second = circular_cluster(:second, pulse_to_test())
      switchboard = switchboard_from([first, second])
    
      UT.initial_pulse(to: :first, carrying: 1, via: switchboard)
      assert_receive(2)
    end

    def initialize_with_empty_pids do
      fn _configuration -> %{pids: []} end
    end

    def pulse_accumulated_pids() do
      fn :nothing, configuration, mutable ->
        mutated = update_in(mutable.pids, &([self() | &1]))
        configuration.send_pulse_downstream.(carrying: mutated.pids)
        mutated
      end
    end

    test "succeeding pulses go to the same process" do
      first = circular_cluster(:first,
                               pulse_accumulated_pids(),
                               initialize_mutable: initialize_with_empty_pids())
      second = circular_cluster(:second, pulse_to_test())
      switchboard = switchboard_from([first, second])

      UT.initial_pulse(to: :first, carrying: :nothing, via: switchboard)
      [first_pid] = assert_receive(_)

      UT.initial_pulse(to: :first, carrying: :nothing, via: switchboard)
      assert_receive([^first_pid, ^first_pid])
    end

    test "... however, processes 'age out'" do
      first = circular_cluster(:first,
                               pulse_accumulated_pids(),
                               initialize_mutable: initialize_with_empty_pids())
      second = circular_cluster(:second, pulse_to_test())
      switchboard = switchboard_from([first, second])

      UT.initial_pulse(to: :first, carrying: :nothing, via: switchboard)
      [first_pid] = assert_receive(_)

      Process.sleep(3000)
      UT.initial_pulse(to: :first, carrying: :nothing, via: switchboard)

      [second_pid] = assert_receive(_)
      refute second_pid == first_pid
    end
  end
end
