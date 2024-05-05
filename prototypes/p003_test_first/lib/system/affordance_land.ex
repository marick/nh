alias AppAnimal.System

defmodule System.AffordanceLand do
  @moduledoc """
  Represents the document in a way that produces affordances and
  accepts actions in the form of instructions to create an affordance.
  See JARGON.md.

  It is rudimentarily scriptable, so that a test can tell it how to
  respond to an action.


  Note that incoming actions are *not* Pulses, for no particularly good reasons.
  Affordances are, however, sent as Pulses, though they should probably be a different
  type.
  """
  use AppAnimal
  use AppAnimal.StructServer
  use TypedStruct
  alias System.{ActivityLogger,Switchboard,Pulse,Affordance,Action}

  typedstruct do
    field :p_switchboard, pid
    field :p_logger, pid
    field :programmed_responses, list, default: []
    field :affordances, list, default: []
  end

  runs_in_sender do
    # I'd rather not have this layer of indirection, but it's needed for tests to use
    # start_supervised.
    def start_link(opts) do
      GenServer.start_link(__MODULE__, opts)
    end

    @doc """
    Given a name/pulse pair, send that affordance to the given name.

    Affordances have the same name as the PerceptionEdge that receives them.
    """
    def cast__produce_spontaneous_affordance(p_affordances, named: name, pulse: pulse),
        do: GenServer.cast(p_affordances, {:produce_this_affordance, name, pulse})

  end

  runs_in_receiver do
    def init(opts) do
      {:ok, struct(__MODULE__, opts)}
    end

    def handle_cast({:produce_this_affordance, affordance_name, %Pulse{} = pulse},
                    s_affordances) do
      cluster_name = affordance_name # this is for documentation
      Switchboard.cast(s_affordances.p_switchboard, :distribute_pulse,
                       carrying: pulse, to: [cluster_name])
      continue(s_affordances)
    end

    def handle_cast({:respond_to, action_name, affordances},
                    s_affordances) do
      s_affordances
      |> Map.update!(:affordances, & &1 ++ [{action_name, affordances}])
      |> continue()
    end

    def handle_cast({:take_action, %Action{} = action}, s_affordances) do
      {responses, remaining_affordances} =
        Keyword.pop_first(s_affordances.affordances, action.type)

      if responses == nil,
         do: IO.puts("==== SAY, there is no affordance for #{action.type}. Test error.")

      ActivityLogger.log_action_received(s_affordances.p_logger, action.type, action.data)
      for %Affordance{} = response <- responses do
        handle_cast({:produce_this_affordance, response.downstream, response.pulse},
                    s_affordances)
      end

      %{s_affordances | affordances: remaining_affordances}
      |> continue()
    end

    unexpected_cast()

    private do
      def append_programmed_responses(keywords, new) do
        wrapped = Enum.map(new, &wrap/1)
        keywords ++ wrapped
      end

      def wrap({action, responses}) do
        case responses do
          _ when is_list(responses) ->
            {action, responses}
          _ ->
            {action, [responses]}
        end
      end
    end
  end
end
