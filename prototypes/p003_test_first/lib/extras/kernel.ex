defmodule AppAnimal.Extras.Kernel do
  def constantly(value) do
    fn _ -> value end
  end
end
