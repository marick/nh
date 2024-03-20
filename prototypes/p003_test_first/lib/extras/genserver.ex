defmodule AppAnimal.GenServer do
  @moduledoc "might make how a GenServer works more clear to reader"
  defmacro __using__(_opts)  do
    quote do
      use GenServer
      require AppAnimal.GenServer
      import AppAnimal.GenServer
      alias AppAnimal.Neural
      alias AppAnimal.Cluster      
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

  # special names for my style of genserver. Allows pipelines.
  def continue(mutable),
      do: {:noreply, mutable}  # for `cast`
  def continue(mutable, returning: retval),
      do: {:reply, retval, mutable}

  def stop(arg), do: {:stop, :normal, arg}
end

