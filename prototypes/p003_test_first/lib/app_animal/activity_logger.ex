alias AppAnimal.System

defmodule System.ActivityLogger do
  @moduledoc """
  Record pulses, etc.

  This is super crude right now. Needs a causality trace, grouping of messages when
  they come from the same cluster, etc.

  Spilling the log to the terminal while the action is ongoing is probably a bad idea.
  For one thing, it can delay messages so that `assert_receive` fails.

  Someday investigate using `Logger`.

  """
  use AppAnimal
  use AppAnimal.StructServer
  use MoveableAliases
  require CircularBuffer
  alias AppAnimal.Cluster

  defstruct [:buffer, also_to_terminal: false]

  defmodule PulseSent do
    typedstruct enforce: true do
      field :cluster_id, Cluster.Identification.t
      field :pulse, Pulse.t
    end

    def new(%Cluster.Identification{} = id, pulse_data) do
      %__MODULE__{cluster_id: id, pulse: Pulse.ensure(pulse_data)}
    end

    def new(cluster, pulse_data), do: new(cluster.id, pulse_data)
  end

  defmodule ActionReceived do
    typedstruct enforce: true do
      field :name, atom
      field :action, Action.t
    end

    def new(name, data \\ nil), do: %__MODULE__{name: name, action: data}
  end


  # An earlier version of this module used
  #    Logger.put_process_level(self(), :debug)
  # It turns out that isn't implemented.
  # https://elixirforum.com/t/struggling-with-logger-put-process-level/58702
  #
  # So instead of relying on each ActivityLogger being an independent process,
  # I have to mess around with state. Bah. As a result of its history, this is
  # probably the Wrong Thing.

  runs_in_sender do
    def start_link(buffer_size \\ 100) do
      GenServer.start_link(__MODULE__, buffer_size)
    end

    def spill_log_to_terminal(pid) do
      GenServer.call(pid, [also_to_terminal: true])
    end

    def silence_terminal_log(pid) do
      GenServer.cast(pid, [also_to_terminal: false])
    end

    def log_pulse_sent(pid, source, pulse) do
      entry = PulseSent.new(source, pulse)
      GenServer.cast(pid, [log: entry])
    end

    def log_action_received(pid, name, data) do
      entry = ActionReceived.new(name, data)
      GenServer.cast(pid, [log: entry])
    end

    def get_log(pid) do
      GenServer.call(pid, :get_log)
    end
  end

  runs_in_receiver do
    def init(buffer_size) do
      %__MODULE__{buffer: CircularBuffer.new(buffer_size)}
      |> ok()
    end

    def handle_call([also_to_terminal: value], _from, me) do
      %{me | also_to_terminal: value}
      |> continue(returning: :ok)
    end

    def handle_call(:get_log, _from, me) do
      continue(me, returning: CircularBuffer.to_list(me.buffer))
    end

    def handle_cast([log: entry], me) do
      maybe_log(me.also_to_terminal, entry)

      update_in(me.buffer, &(CircularBuffer.insert(&1, entry)))
      |> continue
    end
  end

  private do
    # This is all awful, but the whole thing needs rework.

    def maybe_log(false, _) do
    end

    def maybe_log(true, %ActionReceived{} = entry) do
      t =
        if is_atom(entry.action),
           do: entry.action,
           else: entry.action.data

      Logger.info(inspect(t))
    end

    def maybe_log(true, %PulseSent{} = entry) do
      t =
        if is_atom(entry.pulse),
           do: entry.pulse,
           else: entry.pulse.data

      Logger.info(inspect(t), pulse_entry: entry)
    end
  end
end
