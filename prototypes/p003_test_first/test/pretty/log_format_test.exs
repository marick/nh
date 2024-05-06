alias AppAnimal.Pretty

defmodule Pretty.LogFormatTest do
  use AppAnimal.Case, async: true
  alias Pretty.LogFormat, as: UT

  test "modifying newlines" do
    returns = run_and_assert(&UT.handle_newlines/2)

    ["abc\n\ndef", [newlines: :visible]] |> returns.("abc\\n\\ndef")
    ["abc\n\ndef", [                  ]] |> returns.("abc\n\ndef")
  end
end
