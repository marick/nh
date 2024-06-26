defmodule AppAnimal.AffordanceLand do
  @moduledoc """
  Represents the document in a way that produces affordances and
  accepts actions in the form of instructions to create an affordance.
  See JARGON.md.

  It is rudimentarily scriptable, so that a test can tell it how to
  respond to an action.
  """
  use AppAnimal
  use AppAnimal.StructServer
  use KeyConceptAliases
  use Moveable.MoveableAliases

  typedstruct do
    field :p_switchboard, pid
    field :p_logger, pid
    field :programmed_responses, list, default: []
    field :scripted_affordances, list, default: []
  end

  runs_in_receiver do
    def init(opts) do
      {:ok, struct(__MODULE__, opts)}
    end

    handle_CAST do
      def handle_cast({:take_action, %Action{} = action}, s_affordance_land) do
        {responses, remaining_affordances} =
          Keyword.pop_first(s_affordance_land.scripted_affordances, action.type)

        if responses == nil,
           do: IO.puts("==== SAY, there is no affordance for #{action.type}. Test error.")

        ActivityLogger.log_action_received(s_affordance_land.p_logger, action)
        for %Moveable.ScriptedReaction{} = response <- responses do
          cast_affordance_into_network(s_affordance_land.p_switchboard,
                                       response.pulse, response.perception_edge)
        end

        %{s_affordance_land | scripted_affordances: remaining_affordances}
        |> continue()
      end

      def handle_cast({:pulse_to_cluster, opts}, s_affordance_land) do
        [cluster_name, pulse] = Opts.required!(opts, [:to_cluster, :pulse])
        cast_affordance_into_network(s_affordance_land.p_switchboard, pulse, cluster_name)
        continue(s_affordance_land)
      end

      def handle_cast({:respond_to, action_name, affordances}, s_affordance_land) do
        s_affordance_land
        |> Map.update!(:scripted_affordances, & &1 ++ [{action_name, affordances}])
        |> continue()
      end
    end

    private do
      def cast_affordance_into_network(p_switchboard, pulse, cluster_name) do
        Switchboard.cast(p_switchboard, :fan_out, pulse, to: [cluster_name])
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
