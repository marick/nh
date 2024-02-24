defmodule AppAnimal.Pretty.ModuleTest do
  use ExUnit.Case
  alias AppAnimal.Pretty.Module, as: UT
  import FlowAssertions.TabularA

  test "terse display for modules" do
    becomes = run_and_assert(&UT.terse/1)

    A.B.C  |> becomes.("B.C")
    A.B    |> becomes.("A.B")
    A      |> becomes.("A")

    # Not all atoms are module names.
    :a     |> becomes.(":a")
  end

  test "minimal display for modules" do
    becomes = run_and_assert(&UT.minimal/1)

    A.B.C  |> becomes.("C")
    A.B    |> becomes.("B")
    A      |> becomes.("A")

    # Not all atoms are module names.
    :a     |> becomes.(":a")
  end

  test "terse and minimal work for lists" do
    assert UT.terse(  [A.B.C]) == "[B.C]"
    assert UT.minimal([A.B.C]) ==   "[C]"
  end
end
