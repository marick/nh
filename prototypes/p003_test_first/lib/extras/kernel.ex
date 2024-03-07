defmodule AppAnimal.Extras.Kernel do
  def constantly(value) do
    fn _ -> value end
  end

  def pi [{tag, value}] do
    IO.puts "#{tag}: #{inspect value}"
end
end
