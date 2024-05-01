AppAnimal.System

defmodule System.MoveableTest do
  use AppAnimal.Case, async: true
  alias System.Moveable, as: UT
  alias System.Router
  alias System.{Pulse,Action,Delay}

  describe "system router" do
    def as_cast_delivers(data), do: {:"$gen_cast", data}

    test "sending a pulse FROM" do
      router = Router.new(%{Pulse =>  self()})

      pulse = Pulse.new("data")

      UT.cast(pulse, router, :some_cluster_name)

      actual = assert_receive(_)
      expected = as_cast_delivers({:distribute_pulse, carrying: pulse, from: :some_cluster_name})
      assert actual == expected
    end

    test "sending an action" do
      router = Router.new(%{Action =>  self()})

      action = Action.new(:action_name)
      UT.cast(action, router, :some_name)

      actual = assert_receive(_)
      expected = as_cast_delivers({:take_action, action})
      assert actual == expected
    end

    test "sending a delay" do
      p_timer = start_link_supervised!(Network.Timer)

      router = Router.new(%{Delay => p_timer})

      action = Delay.new(3, "some data")
      UT.cast(action, router, :some_name)

      actual = assert_receive(_)
      expected = as_cast_delivers(Pulse.new("some data"))
      assert actual == expected
    end
  end
end
