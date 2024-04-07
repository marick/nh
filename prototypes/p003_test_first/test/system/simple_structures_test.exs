AppAnimal.System

defmodule System.SimpleStructuresTest do
  use ClusterCase, async: true
  alias System.Router, as: UT
  alias System.{Pulse,Action}

  describe "system router" do
    test "creation" do
      actual = UT.new(%{
                 Action => "affordance pid",
                 Pulse =>  "switchboard pid"})

      action = Action.new(:action_type)
      pulse = Pulse.new("data")
      assert UT.pid_for(actual, action) == "affordance pid"
      assert UT.pid_for(actual, pulse) == "switchboard pid"
    end

    def as_cast_delivers(data), do: {:"$gen_cast", data}

    test "sending a pulse TO" do
      router = UT.new(%{Pulse =>  self()})

      pulse = Pulse.new("data")
      UT.cast_via(router, pulse, to: [:some_cluster_name])

      actual = assert_receive(_)
      expected = as_cast_delivers({:distribute_pulse, carrying: pulse, to: [:some_cluster_name]})
      assert actual == expected
    end

    test "sending a pulse FROM" do
      router = UT.new(%{Pulse =>  self()})

      pulse = Pulse.new("data")
      UT.cast_via(router, pulse, from: :some_cluster_name)

      actual = assert_receive(_)
      expected = as_cast_delivers({:distribute_pulse, carrying: pulse, from: :some_cluster_name})
      assert actual == expected
    end

    @tag :skip
    test "sending an action" do
      router = UT.new(%{Action =>  self()})

      action = Action.new(:action_name)
      UT.cast_via(router, action)

      actual = assert_receive(_)
      expected = as_cast_delivers({:take_action, action})
      assert actual == expected
    end
  end
end
