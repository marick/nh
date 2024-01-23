defmodule AppAnimal.ParagraphFocus.AttendToFragmentsTest do
  use ExUnit.Case
  alias AppAnimal.ParagraphFocus.Perceptual.EdgeDetection
  alias AppAnimal.ParagraphFocus.Control.AttendToFragments, as: UT
  import FlowAssertions.TabularA

  test "determining if editing" do
    returns = run_and_assert(
        	&(EdgeDetection.edge_structure(&1) |> UT.has_fragments?))

    "abc\n"                  |> returns.(false)
    "abc\n\ndef"             |> returns.(false)  # editing, but no fragment
    "abc\n\nfragment\n\ndef" |> returns.(true)

    # I'm not sure if it's possible for there to be leading or trailing blanks, but
    # it doesn't make a difference.
    "\n\nabc\n\nfragment\n\ndef\n\n" |> returns.(true)
  end
    
end

