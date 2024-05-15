alias AppAnimal.System.Moveable

defmodule Moveable.RouterTest do
  use AppAnimal.Case, async: true
  use MoveableAliases
  alias Moveable.Router, as: UT

  test "creation and use" do
    actual = UT.new(%{
               Action => "affordance pid",
               Pulse =>  "switchboard pid"})

    action = Action.new(:action_type)
    pulse = Pulse.new("data")
    assert UT.pid_for(actual, action) == "affordance pid"
    assert UT.pid_for(actual, pulse) == "switchboard pid"
  end
end
