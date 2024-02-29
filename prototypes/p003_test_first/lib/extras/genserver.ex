defmodule AppAnimal.GenServer do
  @moduledoc "might make how a GenServer works more clear to reader"
  defmacro __using__(_opts)  do
    quote do
      use GenServer
      require AppAnimal.GenServer
      import AppAnimal.GenServer
    end
  end

  defmacro runs_in_sender(do: block) do
    quote do
      unquote(block)
    end
  end

  defmacro runs_in_receiver(do: block) do
    quote do
      unquote(block)
    end
  end

  defmodule Tuples do
    def noreply(mutable), do: {:noreply, mutable}
  end
end

