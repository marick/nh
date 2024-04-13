alias AppAnimal.Network

defmodule Network.Timer do
  use AppAnimal
  use AppAnimal.GenServer

  runs_in_sender do 
    def start_link(_) do
      GenServer.start_link(__MODULE__, :ok)
    end
    
    def cast(self, payload, every: millis, to: destination_pid) do
      GenServer.call(self, {:cast_every, millis, payload, destination_pid})
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
    def handle_call({:cast_every, millis, payload, p_destination}, _from, :ok) do
      repeating(every: millis, sending: payload, to: p_destination)
      continue(:ok, returning: :ok)
    end

    def handle_call({:cast_after, millis, payload}, {on_behalf_of, _}, :ok) do
      once(after: millis, sending: payload, to: on_behalf_of)
      continue(:ok, returning: :ok)
    end

    @impl GenServer
    def handle_info([every: _millis, sending: payload, to: pid] = opts, :ok) do
      GenServer.cast(pid, payload)
      repeating(opts)
      continue(:ok)
    end

    def handle_info([sending: payload, to: pid], :ok) do
      GenServer.cast(pid, payload)
      continue(:ok)
    end
    
    private do
      def repeating([every: millis, sending: _payload, to: _on_behalf_of] = opts) do
        Process.send_after(self(), opts, millis)
      end

      def once([after: millis, sending: payload, to: on_behalf_of]) do
        Process.send_after(self(), [sending: payload, to: on_behalf_of], millis)
      end
    end
  end
end
