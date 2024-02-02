defmodule AppAnimal.Pretty.FormatterTest do
  use ExUnit.Case
  alias MyFormat, as: UT
  import FlowAssertions.TabularA

  test "modifying newlines" do
    returns = run_and_assert(&UT.handle_newlines/2)

    ["abc\n\ndef", [newlines: :visible]] |> returns.("abc\\n\\ndef")
    ["abc\n\ndef", [                  ]] |> returns.("abc\n\ndef")
  end
end

