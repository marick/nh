defmodule AppAnimal.ParagraphFocus.EnvironmentTest do
  # import AppAnimal.ParagraphFocus.Environment
  use ExUnit.Case

  # setup do
  #   paragraph = start_supervised!({Environment, %{text: "abc", cursor: 1}})
  #   %{paragraph: paragraph}
  # end


  # test "creation", %{paragraph: paragraph} do
  #   GenServer.cast(paragraph, {:insert, "123"})
  #   assert GenServer.call(paragraph, :text) == "a123bc"
  #   assert GenServer.call(paragraph, :cursor) == 4
  # end
end
