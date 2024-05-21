alias AppAnimal.Network

defmodule Network.Timer do
  @moduledoc """
  Schedule delayed sending of `AppAnimal.Moveable` structures.

  A circular cluster may send a `Delay` message to a `Timer` process,
  specifying an interval after which an included pulse should be
  `cast` back at that cluster. As with other pulses, the casting is done via
  the `AppAnimal.Switchboard`.

  Independently, the process casts a `:time_to_throb` message to a
  single receiving process at given intervals. It's that process's job to fan the
  message out to all currently active/throbbing circular clusters.

  It seems unlikely this is the right design, or that these two
  responsibilities should be wrapped up together.
  """
  use AppAnimal
  use AppAnimal.StructServer
  use KeyConceptAliases

  typedstruct module: ThrobInstructions, enforce: true do
    field :interval, Integer
    field :p_notify, pid
  end

  typedstruct module: DelayedPulseInstructions, enforce: true do
    field :p_switchboard, pid
    field :pulse, Pulse.t
    field :destination_name, atom
  end

  @no_state :no_state

  runs_in_sender do
    def start_link(_),
        do: GenServer.start_link(__MODULE__, @no_state)

    def begin_throbbing(self, every: millis, notify: p_notify) do
      instructions = %ThrobInstructions{interval: millis, p_notify: p_notify}
      GenServer.call(self, instructions)
    end

    def delayed(self, pulse, opts) do
      [interval, p_switchboard, destination_name] =
        Opts.required!(opts, [:after, :via_switchboard, :destination])
      instructions = %DelayedPulseInstructions{p_switchboard: p_switchboard,
                                               pulse: pulse,
                                               destination_name: destination_name}
      GenServer.call(self, {instructions, interval})
    end
  end

  handle_CALL do  # initiate future behavior
    def handle_call(%ThrobInstructions{} = instructions, _from, @no_state) do
      repeating(instructions)
      continue(@no_state, returning: :ok)
    end

    def handle_call({%DelayedPulseInstructions{} = instructions, delay}, _from, @no_state) do
      Process.send_after(self(), instructions, delay)
      continue(@no_state, returning: :ok)
    end
  end

  handle_INFO do # Erlan's timer delivers notificiations view info messages

    def handle_info(%ThrobInstructions{} = instructions, @no_state) do
      GenServer.cast(instructions.p_notify, :time_to_throb)
      repeating(instructions)
      continue(@no_state)
    end

    def handle_info(%DelayedPulseInstructions{} = instructions, @no_state) do
      Switchboard.cast(instructions.p_switchboard,
                       :fan_out, instructions.pulse, to: [instructions.destination_name])
      continue(@no_state)
    end
  end

  private do
    def repeating(%ThrobInstructions{} = instructions) do
      Process.send_after(self(), instructions, instructions.interval)
    end
  end
end
