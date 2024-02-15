defmodule AppAnimal.ParagraphFocus.AttendToEditing do
  use ExUnit.Case
  alias AppAnimal.ParagraphFocus.Perceptual.EdgeSummarizer
  alias AppAnimal.ParagraphFocus.Control.AttendToEditing, as: UT
  import FlowAssertions.TabularA

  test "determining if editing" do
    returns = run_and_assert(
        	&(EdgeSummarizer.edge_structure(&1) |> UT.activate_downstream?))

    "abc\n"         |> returns.(false)
    "abc\n\ndef"    |> returns.(true)

    # A fragment doesn't is part of continued editing
    "abc\n\nfragment\n\ndef" |> returns.(true)

    # I'm not sure if it's possible for there to be leading or trailing blanks, but
    # it doesn't make a difference.
    "\n\nabc\n\ndef\n\n"    |> returns.(true)
  end
    
end

