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
  use AppAnimal.StructServer
  alias System.{ActivityLogger,Switchboard,Action}

  typedstruct do
    field :p_switchboard, pid
    field :p_logger, pid
    field :programmed_responses, list, default: []
    field :affordances, list, default: []
  end

  runs_in_receiver do
    def init(opts) do
      {:ok, struct(__MODULE__, opts)}
    end

    handle_CAST do
      def handle_cast({:take_action, %Action{} = action}, s_affordances) do
        {responses, remaining_affordances} =
          Keyword.pop_first(s_affordances.affordances, action.type)

        if responses == nil,
           do: IO.puts("==== SAY, there is no affordance for #{action.type}. Test error.")

        ActivityLogger.log_action_received(s_affordances.p_logger, action.type, action.data)
        for %Moveable.ScriptedReaction{} = response <- responses do
          cast_affordance_into_network(s_affordances.p_switchboard,
                                       response.pulse, response.perception_edge)
        end

        %{s_affordances | affordances: remaining_affordances}
        |> continue()
      end

      def handle_cast({:pulse_to_cluster, opts}, s_affordances) do
        [cluster_name, pulse] = Opts.required!(opts, [:to_cluster, :pulse])
        cast_affordance_into_network(s_affordances.p_switchboard, pulse, cluster_name)
        continue(s_affordances)
      end

      def handle_cast({:respond_to, action_name, affordances}, s_affordances) do
        s_affordances
        |> Map.update!(:affordances, & &1 ++ [{action_name, affordances}])
        |> continue()
      end
    end

    private do
      def cast_affordance_into_network(p_switchboard, pulse, cluster_name) do
        Switchboard.cast(p_switchboard, :distribute_pulse,
                         carrying: pulse, to: [cluster_name])
      end

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
