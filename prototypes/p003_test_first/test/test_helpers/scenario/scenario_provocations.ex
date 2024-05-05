alias AppAnimal.{Scenario,TestHelpers}

defmodule Scenario.Provocations do
  use AppAnimal
  import Scenario.ProcessKludgery
  alias TestHelpers.Animal

  def provocation(thunk), do: provocation_thunks([thunk])

  def take_action(opts) do
    fn animal -> Animal.take_action(animal, opts) end
  end

  def send_test_pulse(opts) do
    fn animal -> Animal.send_test_pulse(animal, opts) end
  end

  def spontaneous_affordance(opts) do
    fn animal -> Animal.spontaneous_affordance(animal, opts) end
  end
end
