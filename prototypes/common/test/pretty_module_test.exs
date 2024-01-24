defmodule AppAnimal.PrettyModuleTest do
  use ExUnit.Case
  alias AppAnimal.PrettyModule
  import FlowAssertions.TabularA

  test "terse display for modules" do
    becomes = run_and_assert(&PrettyModule.terse/1)

    A.B.C  |> becomes.("B.C")
    A.B    |> becomes.("A.B")
    A      |> becomes.("A")

    # Not all atoms are module names.
    :a     |> becomes.(":a")
  end

  test "minimal display for modules" do
    becomes = run_and_assert(&PrettyModule.minimal/1)

    A.B.C  |> becomes.("C")
    A.B    |> becomes.("B")
    A      |> becomes.("A")

    # Not all atoms are module names.
    :a     |> becomes.(":a")
  end

  test "terse and minimal work for lists" do
    assert PrettyModule.terse(  [A.B.C]) == "[B.C]"
    assert PrettyModule.minimal([A.B.C]) ==   "[C]"
  end
end
