alias AppAnimal.{System,Scenario}


defmodule System.SwitchboardTest do
  use AppAnimal
  use Scenario.Case, async: true

  # At this point, the switchboard is tested indirectly, via tests of the features
  # that make use of the switchboard.
end
