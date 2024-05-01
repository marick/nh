AppAnimal.System

defmodule System.MoveableTest do
  use AppAnimal.Case, async: true
  alias System.Moveable, as: UT
  alias System.{Router}
  alias System.{Pulse,Action,Delay}
  alias AppAnimal.Clusterish

  describe "system router" do
    def as_cast_delivers(data), do: {:"$gen_cast", data}

    test "sending a pulse FROM" do
      clusterish = Clusterish.Minimal.new(:some_cluster_name,
                                          Router.new(%{Pulse =>  self()}))
      pulse = Pulse.new("data")

      UT.cast(pulse, clusterish)

      actual = assert_receive(_)
      expected = as_cast_delivers({:distribute_pulse, carrying: pulse, from: :some_cluster_name})
      assert actual == expected
    end

    test "sending an action" do
      clusterish = Clusterish.Minimal.new(:some_cluster_name,
                                          Router.new(%{Action =>  self()}))

      action = Action.new(:action_name)
      UT.cast(action, clusterish)

      actual = assert_receive(_)
      expected = as_cast_delivers({:take_action, action})
      assert actual == expected
    end

    test "sending a delay" do
      p_timer = start_link_supervised!(Network.Timer)

      clusterish = Clusterish.Minimal.new(:some_cluster_name,
                                          Router.new(%{Delay => p_timer}))

      action = Delay.new(3, "some data")
      UT.cast(action, clusterish)

      actual = assert_receive(_)
      expected = as_cast_delivers(Pulse.new("some data"))
      assert actual == expected
    end

    @tag :test_uses_sleep
    test "sending a collection of moveables" do
      p_timer = start_link_supervised!(Network.Timer)
      clusterish = Clusterish.Minimal.new(:some_cluster_name,
                                          Router.new(%{Pulse => self(),
                                                       Delay => p_timer}))
      pulse = Pulse.new("data")
      delay_pulse = Pulse.new("delay data")
      delay = Delay.new(Duration.quantum, delay_pulse)
      collection = UT.Collection.new([pulse, delay])

      UT.cast(collection, clusterish)

      assert_receive({:"$gen_cast", {:distribute_pulse, carrying: ^pulse, from: :some_cluster_name}})

      Process.sleep(10)
      {:"$gen_cast", received_delay_pulse} = assert_receive(_)
      assert received_delay_pulse == delay_pulse
    end
  end
end
