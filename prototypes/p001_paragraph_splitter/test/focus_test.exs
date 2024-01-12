defmodule FocusTest do
  use ExUnit.Case

  setup do
    focus = start_supervised!(Paragraph.Focus)
    %{focus: focus}
  end

  test "basic", %{focus: focus} do
    GenServer.call(focus, {:focus_on_paragraph, "abc", 1})
    GenServer.call(:current_paragraph, {:add, "!"})
    GenServer.call(:current_paragraph, {:add, "\n"})
    GenServer.call(:current_paragraph, {:add, "\n"})
  end
end
