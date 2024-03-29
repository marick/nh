alias AppAnimal.System

defmodule System.AffordanceLand do
  @moduledoc """
  Represents the document in a way that produces affordances and
  accepts actions in the form of instructions to create an affordance. 
  See JARGON.md.

  It is rudimentarily scriptable, so that a test can tell it how to
  respond to an action.
  """
  use AppAnimal
  use AppAnimal.GenServer
  use TypedStruct
  alias System.{ActivityLogger,Switchboard}

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
    Given a name/data pair, send that affordance into the network.
    """
    def cast__produce_affordance(p_affordances, [{name, data}]),
        do: GenServer.cast(p_affordances, [:produce_this_affordance, {name, data}])
    
  end

  runs_in_receiver do
    def init(opts) do
      {:ok, struct(__MODULE__, opts)}
    end

    def handle_cast([:produce_this_affordance, {name, data}], s_affordances) do
      Switchboard.cast__distribute_pulse(s_affordances.p_switchboard,
                                         carrying: data, to: [name])
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
      for response <- responses do
        handle_cast([:produce_this_affordance, response], s_affordances)
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
