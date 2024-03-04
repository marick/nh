defmodule AppAnimal.Neural.PulseLogger do
  use AppAnimal
  use AppAnimal.GenServer
  require CircularBuffer


  defstruct [:buffer, also_to_terminal: false]
  
  defmodule Entry do
    @enforce_keys [:cluster_type, :name, :pulse_data]
    defstruct [:cluster_type, :name, :pulse_data]
  end

  # An earlier version of this modul used
  #    Logger.put_process_level(self(), :debug)
  # It turns out that isn't implemented.
  # https://elixirforum.com/t/struggling-with-logger-put-process-level/58702
  #
  # So instead of relying on each PulseLogger being an independent process,
  # I have to mess around with state. Bah. As a result of its history, this is
  # probably the Wrong Thing.
  

  runs_in_sender do 
    def start_link(buffer_size \\ 100) do
      GenServer.start_link(__MODULE__, buffer_size)
    end
    
    def spill_log_to_terminal(pid, value) do
      GenServer.call(pid, [also_to_terminal: value])
    end

    def log(pid, type, name, pulse_data) do
      entry = %Entry{cluster_type: type, name: name, pulse_data: pulse_data}
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
      {:reply, :ok, %{me | also_to_terminal: value}}
    end

    def handle_call(:get_log, _from, me) do
      {:reply, CircularBuffer.to_list(me.buffer), me}
    end

    def handle_cast([log: entry], me) do
      if me.also_to_terminal,
         do: Logger.info(inspect(entry.pulse_data), pulse_entry: entry)
      
      update_in(me.buffer, &(CircularBuffer.insert(&1, entry)))
      |> continue
    end
  end
end
