alias AppAnimal.{Network,System,Cluster}

defmodule Network.CircularSubnet do
  @moduledoc """
  The portion of a `Network` that changes state as circular clusters
  are started and stop.

  This keeps track of the lifespan of throbbing clusters. It also sends messages
  to them. This hides knowledge of lifespans inside this module.

  This module stores all the circular clusters known in the `Network`, not just the
  ones that are actively throbbing. It stores them in a whittled-down form, not including
  fields irrelevant to this module's purpose.

  Linear and Circular clusters really want to inherit from some Cluster supertype, but
  I don't see how to represent that in a non-cringy way.
  """
  use AppAnimal
  use AppAnimal.GenServer
  use TypedStruct
  alias System.Pulse

  typedstruct enforce: true do
    plugin TypedStructLens

    field :name_to_pid, BiMap.t(atom, pid), default: BiMap.new
    field :name_to_cluster, %{atom => Cluster.Circular.t}
  end

  runs_in_sender do
    def start_link(clusters_and_maybe_more) do
      GenServer.start_link(__MODULE__, clusters_and_maybe_more)
    end

    def cast__distribute_pulse(pid, carrying: %Pulse{} = pulse, to: destination_names),
        do: GenServer.cast(pid, {:distribute_pulse, carrying: pulse, to: destination_names})


    def call__add_cluster(pid, cluster), do: GenServer.call(pid, [add: cluster])

    def add_router_to_all(pid, router), do: GenServer.call(pid, [add_router_to_all: router])

    def router_for(pid, name), do: GenServer.call(pid, [router_for: name])

    private do
      # For tests
      def names(pid), do: GenServer.call(pid, :names)
      def clusters(pid), do: GenServer.call(pid, :clusters)
      def throbbing_names(pid), do: GenServer.call(pid, :throbbing_names)
      def throbbing_pids(pid), do: GenServer.call(pid, :throbbing_pids)

      def throb_to_test(pid, name: name, pid: fake_cluster_pid) do
        GenServer.call(pid, {:throb_to_test, name, fake_cluster_pid})
      end
    end
  end

  runs_in_receiver do
    @impl GenServer
    def init(clusters) do
      indexed =
        for c <- clusters, into: %{} do
          {c.name, Cluster.Circular.new(c)}  # TODO: should use c itself when `Shape` goes away
        end
      {:ok, %__MODULE__{name_to_cluster: indexed}}
    end

    @impl GenServer
    def handle_cast({:distribute_pulse, carrying: %Pulse{} = pulse, to: names}, s_state) do
      s_mutated = ensure_started(s_state, names)

      for name <- names do
        pid = BiMap.fetch!(s_mutated.name_to_pid, name)
        GenServer.cast(pid, [handle_pulse: pulse])
      end
      continue(s_mutated)
    end

    def handle_cast(:time_to_throb, s_state) do
      throb(BiMap.values(s_state.name_to_pid))
      continue(s_state)
    end

    unexpected_cast()

    @impl GenServer
    def handle_info({:DOWN, _, :process, pid, _}, s_state) do
      s_state.name_to_pid
      |> BiMap.delete_value(pid)
      |> then(& Map.put(s_state, :name_to_pid, &1))
      |> continue
    end

    # This is used for testing as a way to get internal values of clusters.
    @impl GenServer
    def handle_call([forward: getter_name, to: name], _from, s_state) do
      result =
        BiMap.get(s_state.name_to_pid, name)
        |> GenServer.call(getter_name)
      continue(s_state, returning: result)
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

    def handle_call([router_for: name], _from, s_state) do
      cluster = s_state.name_to_cluster[name]
      continue(s_state, returning: cluster.router)
    end

    def handle_call({:throb_to_test, name, pid}, _from, s_state) do
      s_state.name_to_pid
      |> BiMap.put(name, pid)
      |> then(& Map.put(s_state, :name_to_pid, &1))
      |> continue(returning: :ok)
    end


    def handle_call([add: %Cluster.Circular{} = cluster], _from, s_state) do
      precondition Map.has_key?(s_state, :name_to_cluster)

      s_state
      |> A.put(name_to_cluster() |> Lens.key(cluster.name), cluster)
      |> continue(returning: :ok)
    end

    def handle_call([add_router_to_all: router], _from, s_state) do
      lens = Lens.key(:name_to_cluster) |> Lens.map_values() |> Cluster.Circular.router()
      s_state
      |> A.put(lens, router)
      |> continue(returning: :ok)
    end

    unexpected_call()

    private do
      def ensure_started(s_state, names) do
        reducer = fn name, bimap ->
          if BiMap.has_key?(bimap, name) do
            bimap
          else
            cluster = Map.get(s_state.name_to_cluster, name)
            {:ok, pid} = GenServer.start(Cluster.Process, cluster)
            Process.monitor(pid)
            BiMap.put(bimap, name, pid)
          end
        end

        new_bimap = Enum.reduce(names, s_state.name_to_pid, reducer)
        %{s_state | name_to_pid: new_bimap}
      end

      def throb(pids) do
        for pid <- pids,
            do: GenServer.cast(pid, [throb: 1])
      end
    end
  end
end
