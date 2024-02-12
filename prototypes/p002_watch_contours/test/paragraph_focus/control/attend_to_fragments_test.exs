defmodule AppAnimal.ParagraphFocus.AttendToFragmentsTest do
  use ExUnit.Case
  alias AppAnimal.ParagraphFocus.Perceptual.EdgeDetection
  alias AppAnimal.ParagraphFocus.Control.AttendToFragments, as: UT
  import FlowAssertions.TabularA

  test "checking for fragments" do
    returns = run_and_assert(
        	&(EdgeDetection.edge_structure(&1) |> UT.activate_downstream?))

    "abc\n"                  |> returns.(false)
    "abc\n\ndef"             |> returns.(false)  # editing, but no fragment
    "abc\n\nfragment\n\ndef" |> returns.(true)

    # I'm not sure if it's possible for there to be leading or trailing blanks, but
    # it doesn't make a difference.
    "\n\nabc\n\nfragment\n\ndef\n\n" |> returns.(true)
  end

  test "returning the first fragment indicator" do
    returns = run_and_assert(
                &(EdgeDetection.edge_structure(&1) |> UT.downstream_data))

    "text\n\nfragment\n\ntext\n\n" |> returns.({:text, 6..13})
    #        ^6     ^13
    
    # Check that a leading gap fools no one
    "\n\ntext\n\nfragment\n\ntext\n\n" |> returns.({:text, 8..15})
    #            ^8     ^15

    # Note that an invalid list is the caller's problem.
  end
end

