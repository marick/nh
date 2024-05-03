alias AppAnimal.Network

defmodule Network.Timer do
  use AppAnimal
  use AppAnimal.GenServer

  typedstruct module: ThrobInstructions, enforce: true do
    field :interval, Integer
    field :p_notify, pid
  end

  # It might be better to have separate processes for throbbing and one-shot timed pulses.

  runs_in_sender do
    def start_link(_) do
      GenServer.start_link(__MODULE__, :ok)
    end

    def begin_throbbing(self, every: millis, notify: p_notify) do
      instructions = %ThrobInstructions{interval: millis, p_notify: p_notify}
      GenServer.call(self, instructions)
    end

    def cast(self, payload, after: millis) do
      GenServer.call(self, {:cast_after, millis, payload})
    end
  end

  runs_in_receiver do
    @impl GenServer
    def init(:ok) do
      ok(:ok)
    end

    @impl GenServer
    def handle_call(%ThrobInstructions{} = instructions, _from, :ok) do
      repeating(instructions)
      continue(:ok, returning: :ok)
    end

    def handle_call({:cast_after, millis, payload}, {on_behalf_of, _}, :ok) do
      once(after: millis, sending: payload, to: on_behalf_of)
      continue(:ok, returning: :ok)
    end

    @impl GenServer
    def handle_info(%ThrobInstructions{} = instructions, :ok) do
      GenServer.cast(instructions.p_notify, :time_to_throb)
      repeating(instructions)
      continue(:ok)
    end

    def handle_info([sending: payload, to: pid], :ok) do
      GenServer.cast(pid, payload)
      continue(:ok)
    end

    private do
      def repeating(%ThrobInstructions{} = instructions) do
        Process.send_after(self(), instructions, instructions.interval)
      end

      def once([after: millis, sending: payload, to: on_behalf_of]) do
        Process.send_after(self(), [sending: payload, to: on_behalf_of], millis)
      end
    end
  end
end
