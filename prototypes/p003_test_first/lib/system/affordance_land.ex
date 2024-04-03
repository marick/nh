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
  use AppAnimal.GenServer
  use TypedStruct
  alias System.{ActivityLogger,Switchboard,Pulse}

  typedstruct do
    field :p_switchboard, pid
    field :p_logger, pid
    field :programmed_responses, list, default: []
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
      Switchboard.cast__distribute_pulse(s_affordances.p_switchboard,
                                         carrying: pulse, to: [cluster_name])
      continue(s_affordances)
    end

    def handle_cast([script: responses], s_affordances) do
      s_affordances
      |> Map.update!(:programmed_responses, & append_programmed_responses(&1, responses))
      |> continue()
    end

    def handle_cast([:take_action, [{name, data}]], s_affordances) do
      {responses, remaining_programmed_responses} =
        Keyword.pop_first(s_affordances.programmed_responses, name)
      
      if responses == nil,
         do: IO.puts("==== SAY, there is no programmed response for #{name}. Test error.")

      ActivityLogger.log_action_received(s_affordances.p_logger, name, data)
      for {cluster_name, pulse_data} <- responses do
        pulse = Pulse.new(pulse_data)
        handle_cast({:produce_this_affordance, cluster_name, pulse},
                    s_affordances)
      end
      
      %{s_affordances | programmed_responses: remaining_programmed_responses}
      |> continue()
    end

    
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
