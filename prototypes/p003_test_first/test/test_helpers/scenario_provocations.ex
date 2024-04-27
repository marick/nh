alias AppAnimal.TestHelpers

defmodule TestHelpers.ScenarioProvocations do
  use AppAnimal
  import TestHelpers.ProcessKludgery
  alias ClusterCase.Helpers, as: LessGrotty

  def provocation(thunk), do: init_provocation_thunk(thunk)

  def take_action(opts) do
    fn animal -> LessGrotty.take_action(animal, opts) end
  end

  def send_test_pulse(opts) do
    fn animal -> LessGrotty.send_test_pulse(animal, opts) end
  end

  def spontaneous_affordance(opts) do
    fn animal -> LessGrotty.spontaneous_affordance(animal, opts) end
  end
end
