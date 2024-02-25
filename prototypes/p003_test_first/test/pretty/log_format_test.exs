defmodule AppAnimal.Pretty.LogFormatTest do
  use ExUnit.Case, async: true
  alias AppAnimal.Pretty.LogFormat, as: UT
  import FlowAssertions.TabularA

  test "modifying newlines" do
    returns = run_and_assert(&UT.handle_newlines/2)

    ["abc\n\ndef", [newlines: :visible]] |> returns.("abc\\n\\ndef")
    ["abc\n\ndef", [                  ]] |> returns.("abc\n\ndef")
  end
end

