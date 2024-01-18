defmodule AppAnimalTest do
  use ExUnit.Case

  setup do
    app_animal = start_supervised!(AppAnimal)
    %{app_animal: app_animal}
  end

end
