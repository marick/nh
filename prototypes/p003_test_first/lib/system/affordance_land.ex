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
  alias System.ActivityLogger

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
  end

  runs_in_receiver do
    def init(opts) do
      {:ok, struct(__MODULE__, opts)}
    end

    def handle_cast([:produce_this_affordance, {name, data}], mutable) do
      GenServer.cast(mutable.p_switchboard,
                     {:distribute_pulse, carrying: data, to: [name]})
      continue(mutable)
    end

    def handle_cast([script: responses], mutable) do
      mutable
      |> Map.update!(:programmed_responses, & append_programmed_responses(&1, responses))
      |> continue()
    end
    
    def handle_cast([:take_action, [{name, data}]], mutable) do
      {responses, remaining_programmed_responses} =
        Keyword.pop_first(mutable.programmed_responses, name)
      
      if responses == nil,
         do: IO.puts("==== SAY, there is no programmed response for #{name}. Test error.")
      
      ActivityLogger.log_action_received(mutable.p_logger, name, data)
      for response <- responses do
        handle_cast([:produce_this_affordance, response], mutable)
      end
      
      %{mutable | programmed_responses: remaining_programmed_responses}
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
