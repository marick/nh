alias AppAnimal.System

defmodule System.RouterTest do
  use AppAnimal.Case, async: true
  alias System.Router, as: UT
  alias System.{Pulse,Action}

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
