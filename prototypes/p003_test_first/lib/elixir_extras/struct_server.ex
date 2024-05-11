defmodule AppAnimal.StructServer do
  @moduledoc "might make how a GenServer works more clear to reader"
  defmacro __using__(_opts)  do
    quote do
      use GenServer
      require AppAnimal.StructServer
      import AppAnimal.StructServer
      alias AppAnimal.Cluster

      def start_link(struct),
          do: GenServer.start_link(__MODULE__, struct)

      @doc """
      `call` and `cast` save the trouble of defining functions that run in
      the client process.

      If you have code implemented as handle_cast({:name, arg}), call it
      with `Server.call(pid, :name, arg)`. `arg` is frequently a keyword list.
      """
      def call(pid, name), do: GenServer.call(pid, name)
      def call(pid, name, arg), do: GenServer.call(pid, {name, arg})

      def cast(pid, name), do: GenServer.cast(pid, name)
      def cast(pid, name, arg), do: GenServer.cast(pid, {name, arg})

      @impl GenServer

      @doc """
      Especially when a genserver manages a struct, there's no need to write a
      special `init` function. Just use this default.
      """
      def init(init_state), do: ok(init_state)

      defoverridable start_link: 1, cast: 3, call: 3, init: 1
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

  # These provide a more pleasant error. Ideally, they'd be automatically included,
  # but they have to be positioned after the definitions they're the default for.
  # So they're manually placed at the end of the module.



  def oops(arg) do
    line = "=========================="
    msg = "No pattern match"
    IO.puts(line)
    dbg {msg, arg}
    IO.puts(line)
    raise "%{msg}: %{inspect arg}"
  end

  defmacro unexpected_call() do
    quote do
      def handle_call(arg, _from, _state), do: oops(arg)
    end
  end

  defmacro unexpected_cast() do
    quote do
      def handle_cast(arg, _state), do: oops(arg)
    end
  end

  defmacro handle_CAST(do: block) do
    quote do
      @impl GenServer
      unquote(block)
      def handle_cast(arg, _state), do: oops(arg)
    end
  end

  defmacro handle_CALL(do: block) do
    quote do
      @impl GenServer
      unquote(block)
      def handle_call(arg, _from, _state), do: oops(arg)
    end
  end

  defmacro handle_INFO(do: block) do
    quote do
      @impl GenServer
      unquote(block)
      def handle_info(arg, _state), do: oops(arg)
    end
  end


  # special names for my style of genserver. Allows pipelines.
  def continue(s_state),
      do: {:noreply, s_state}  # for `cast`
  def continue(s_state, returning: retval),
      do: {:reply, retval, s_state}
  def stop(arg),
      do: {:stop, :normal, arg}
end
