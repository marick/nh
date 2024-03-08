defmodule AppAnimal.Neural.Affordances do
  alias AppAnimal.Neural.ActivityLogger
  use AppAnimal
  use AppAnimal.GenServer

  defstruct [:switchboard_pid,
             logger_pid: :created_at_start_link_time,
             programmed_responses: []]


  def response_to(action, response), do: {action, response}
  def affords([{name, data}]), do: {name, data}
  
  runs_in_sender do
    
    def start_link(keys) do
      GenServer.start_link(__MODULE__, keys)
    end

    def produce_this_affordance(pid, [{name, data}]) do
      GenServer.cast(pid, [:produce_this_affordance, {name, data}])
    end

    def script(pid, list) do
      GenServer.cast(pid, [script: list])
      pid
    end

    def note_action(pid, action) when is_atom(action) do
      note_action(pid, [{action, :no_data}])
    end

    def note_action(pid, [{_name, _data}] = action) do
      GenServer.cast(pid, [:note_action, action])
    end
  end

  runs_in_receiver do
    def init(keys) do
      {:ok, struct(__MODULE__, keys)}
    end

    def handle_cast([:produce_this_affordance, {name, data}], mutable) do
      Neural.Switchboard.forward_affordance(mutable.switchboard_pid,
                                            named: name, conveying: data)
      continue(mutable)
    end

    def handle_cast([script: responses], mutable) do
      mutable
      |> Map.update!(:programmed_responses, & append_programmed_responses(&1, responses))
      |> continue()
    end

    def handle_cast([:note_action, [{name, data}]], mutable) do
      {responses, remaining_programmed_responses} =
        Keyword.pop_first(mutable.programmed_responses, name)

      ActivityLogger.log_action_received(mutable.logger_pid, name, data)
      for response <- responses do
        handle_cast([:produce_this_affordance, response], mutable)
      end

      %{mutable | programmed_responses: remaining_programmed_responses}
      |> continue()
    end
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
