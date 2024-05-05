alias AppAnimal.Network

defmodule Network.Timer do
  use AppAnimal
  use AppAnimal.GenServer
  alias AppAnimal.System.Switchboard

  typedstruct module: ThrobInstructions, enforce: true do
    field :interval, Integer
    field :p_notify, pid
  end

  typedstruct module: DelayedPulseInstructions, enforce: true do
    field :p_switchboard, pid
    field :pulse, Pulse.t
    field :destination_name, atom
  end

  # It might be better to have separate processes for throbbing and one-shot timed pulses.

  runs_in_sender do
    def start_link(_) do
      GenServer.start_link(__MODULE__, :no_state)
    end

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

  runs_in_receiver do
    @impl GenServer
    def init(:no_state) do
      ok(:no_state)
    end

    @impl GenServer
    def handle_call(%ThrobInstructions{} = instructions, _from, :no_state) do
      repeating(instructions)
      continue(:no_state, returning: :ok)
    end

    def handle_call({%DelayedPulseInstructions{} = instructions, delay}, _from, :no_state) do
      Process.send_after(self(), instructions, delay)
      continue(:no_state, returning: :ok)
    end

    @impl GenServer
    def handle_info(%ThrobInstructions{} = instructions, :no_state) do
      GenServer.cast(instructions.p_notify, :time_to_throb)
      repeating(instructions)
      continue(:no_state)
    end

    def handle_info(%DelayedPulseInstructions{} = instructions, :no_state) do
      Switchboard.cast(instructions.p_switchboard, :distribute_pulse,
                       carrying: instructions.pulse,
                       to: [instructions.destination_name])
      continue(:no_state)
    end

    private do
      def repeating(%ThrobInstructions{} = instructions) do
        Process.send_after(self(), instructions, instructions.interval)
      end
    end
  end
end
