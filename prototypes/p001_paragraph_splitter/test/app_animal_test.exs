defmodule AppAnimalTest do
  use ExUnit.Case

  setup do
    app_animal = start_supervised!(AppAnimal)
    %{app_animal: app_animal}
  end

  test "basic", %{app_animal: app_animal} do
    GenServer.call(app_animal, {:focus_on_paragraph, "abc", 1})
    GenServer.call(:current_paragraph, {:add, "!"})
    GenServer.call(:current_paragraph, {:add, "\n"})
    GenServer.call(:current_paragraph, {:add, "\n"})
  end
end
