defmodule AppAnimal.StructServer do
  @moduledoc "might make how a GenServer works more clear to reader"
  import AppAnimal.Extras.Nesting

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


  section "wrappers" do
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

    @doc """
    handle_CAST and friends wrap groups of handle_cast (etc.) functions.

    They take care of `@impl GenServer` and making slightly nicer error messages when
    no function matches.
    """
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
  end


  section "Nicer reporting of unmatched messages (indicating a coding error)" do
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
  end


  alias AppAnimal.Extras.DepthAgnostic, as: A

  @doc """
  Quick definitions of getters based on lenses.
  """
  defmacro def_get_only(lens_descriptions) do
    for {lens_name, arg_count} <- lens_descriptions do
      one_getter(:get_only, lens_name, arg_count)
    end
  end

  defmacro def_get_all(lens_descriptions) do
    for {lens_name, arg_count} <- lens_descriptions do
      one_getter(:get_all, lens_name, arg_count)
    end
  end


  defp one_getter(getter, lens_name, 0) do
    quote do
      def handle_call(unquote(lens_name), _from, s_struct) do
        retval = A.unquote(getter)(s_struct, unquote(lens_name)())
        continue(s_struct, returning: retval)
      end
    end
  end

  defp one_getter(getter, lens_name, arg_count) do
    args = Macro.generate_arguments(arg_count, __MODULE__)
    quote do
      def handle_call({unquote(lens_name), unquote_splicing(args)}, _from, s_struct) do
        retval = A.unquote(getter)(s_struct, unquote(lens_name)(unquote_splicing(args)))
        continue(s_struct, returning: retval)
      end
    end
  end


  @doc """
  Return successfully from a `handle_cast`,`handle_info`, or `handle_info` function.

  `state |> continue` produces the familiar `{:no_reply, state}` return value.

  `state |> continue(returning: retval)` produces `{:reply, retval, state}`.
  """
  def continue(s_state),
      do: {:noreply, s_state}
  def continue(s_state, returning: retval),
      do: {:reply, retval, s_state}

  @doc """
  Request a `:normal` stopping of the process.

  `state |> stop` produces `{:stop, :normal, s_state}`
  """
  def stop(s_state),
      do: {:stop, :normal, s_state}
end
