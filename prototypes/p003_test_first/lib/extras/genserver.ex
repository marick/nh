defmodule AppAnimal.GenServer do
  @moduledoc "might make how a GenServer works more clear to reader"
  defmacro __using__(_opts)  do
    quote do
      use GenServer
      require AppAnimal.GenServer
      import AppAnimal.GenServer
      alias AppAnimal.System
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
  def continue(s_state),
      do: {:noreply, s_state}  # for `cast`
  def continue(s_state, returning: retval),
      do: {:reply, retval, s_state}

  def stop(arg), do: {:stop, :normal, arg}
end

