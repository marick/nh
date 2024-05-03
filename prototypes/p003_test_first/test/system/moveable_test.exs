AppAnimal.System

defmodule System.MoveableTest do
  use AppAnimal.Case, async: true
  alias System.Moveable, as: UT
  alias System.{Router}
  alias System.{Pulse,Action,Delay}
  alias AppAnimal.Clusterish

  describe "system router" do
    test "sending a pulse FROM" do
      clusterish = Clusterish.Minimal.new(:some_cluster_name,
                                          Router.new(%{Pulse => self()}))
      pulse = Pulse.new("data")

      UT.cast(pulse, clusterish)

      assert_receive(_)
      |> assert_distribute_from(pulse: pulse, from: :some_cluster_name)
    end

    test "sending an action" do
      clusterish = Clusterish.Minimal.new(:some_cluster_name,
                                          Router.new(%{Action =>  self()}))

      action = Action.new(:action_name)
      UT.cast(action, clusterish)

      assert_receive(_) |> cast_content
      |> assert_equal({:take_action, action})
    end

    test "sending a delay" do
      p_timer = start_link_supervised!(Network.Timer)
      self_acts_as_switchboard = self()

      clusterish = Clusterish.Minimal.new(:some_cluster_name,
                                          Router.new(%{Delay => p_timer,
                                          Pulse => self_acts_as_switchboard}))

      delay = Delay.new(3, "some data")
      UT.cast(delay, clusterish)

      assert_receive(_)
      |> assert_distribute_to(pulse: Pulse.new("some data"), to: [:some_cluster_name])
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

      assert_receive(_)
      |> assert_distribute_from(from: clusterish.name, pulse: pulse)

      Process.sleep(10)
      assert_receive(_)
      |> assert_distribute_to(to: [clusterish.name], pulse: delay_pulse)
    end
  end
end
