alias AppAnimal.{System,Cluster}
alias System.Network

defmodule Network.CircularClusters do
  use AppAnimal
  use AppAnimal.GenServer
  use TypedStruct

  alias Cluster.CircularProcess
  alias System.Pulse

  typedstruct do
    field :name_to_pid, BiMap.t(atom, pid), default: BiMap.new
    field :name_to_cluster, %{atom => CircularProcess.State.t}, required: true
  end 

  
  runs_in_sender do 
    def start_link(clusters) do
      GenServer.start_link(__MODULE__, clusters)
    end

    def cast__distribute_pulse(pid, carrying: %Pulse{} = pulse, to: destination_names),
        do: GenServer.cast(pid, {:distribute_pulse, carrying: pulse, to: destination_names})
    

    private do 
      # For tests
      def names(pid), do: GenServer.call(pid, :names)
      def clusters(pid), do: GenServer.call(pid, :clusters)
      def throbbing_names(pid), do: GenServer.call(pid, :throbbing_names)
      def throbbing_pids(pid), do: GenServer.call(pid, :throbbing_pids)
    end
  end

  runs_in_receiver do 
    def init(clusters) do
      indexed =
        for c <- clusters, into: %{} do
          {c.name, CircularProcess.State.from_cluster(c)}
        end
      
      {:ok, %__MODULE__{name_to_cluster: indexed}}
    end

    def handle_cast({:distribute_pulse, carrying: %Pulse{} = pulse, to: names}, s_state) do
      s_mutated = ensure_started(s_state, names)

      for name <- names do
        pid = BiMap.fetch!(s_mutated.name_to_pid, name)
        GenServer.cast(pid, [handle_pulse: pulse])
      end
      continue(s_mutated)
    end

    def handle_info({:DOWN, _, :process, pid, _}, s_state) do
      s_state.name_to_pid
      |> BiMap.delete_value(pid)
      |> then(& Map.put(s_state, :name_to_pid, &1))
      |> continue
    end


    def handle_call(:names, _from, s_state) do
      keys = Map.keys(s_state.name_to_cluster)
      continue(s_state, returning: keys)
    end

    def handle_call(:clusters, _from, s_state) do
      values = Map.values(s_state.name_to_cluster)
      continue(s_state, returning: values)
    end

    def handle_call(:throbbing_names, _from, s_state) do
      keys = BiMap.keys(s_state.name_to_pid)
      continue(s_state, returning: keys)
    end

    def handle_call(:throbbing_pids, _from, s_state) do
      values = BiMap.values(s_state.name_to_pid)
      continue(s_state, returning: values)
    end


    private do
      def ensure_started(s_state, names) do
        reducer = fn name, bimap ->
          if BiMap.has_key?(bimap, name) do
            bimap
          else
            cluster = Map.get(s_state.name_to_cluster, name)
            {:ok, pid} = GenServer.start(Cluster.CircularProcess, cluster)
            Process.monitor(pid)
            BiMap.put(bimap, name, pid)
          end
        end
            
        new_bimap = Enum.reduce(names, s_state.name_to_pid, reducer)
        %{s_state | name_to_pid: new_bimap}
      end
    end
  end
end

