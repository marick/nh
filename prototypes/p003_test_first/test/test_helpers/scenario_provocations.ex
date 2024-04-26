alias AppAnimal.TestHelpers

defmodule TestHelpers.ScenarioProvocations do
  use AppAnimal
  import TestHelpers.ProcessKludgery
  alias ClusterCase.Helpers, as: LessGrotty

  def provocation(thunk), do: init_provocation_thunk(thunk)

  def take_action(opts) do
    fn aa -> LessGrotty.take_action(aa, opts) end
  end
end
