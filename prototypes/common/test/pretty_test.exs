defmodule AppAnimal.PrettyTest do
  use ExUnit.Case
  alias AppAnimal.Pretty
  import FlowAssertions.TabularA

  test "terse display for modules" do
    becomes = run_and_assert(&Pretty.terse/1)

    A.B.C  |> becomes.("B.C")
    A.B    |> becomes.("A.B")
    A      |> becomes.("A")

    # Not all atoms are module names.
    :a     |> becomes.(":a")
  end

  test "minimal display for modules" do
    becomes = run_and_assert(&Pretty.minimal/1)

    A.B.C  |> becomes.("C")
    A.B    |> becomes.("B")
    A      |> becomes.("A")

    # Not all atoms are module names.
    :a     |> becomes.(":a")
  end
end
