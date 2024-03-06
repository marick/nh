defmodule AppAnimal.Neural.Affordances do
  use AppAnimal
  use AppAnimal.GenServer

  defstruct [:switchboard,
             logger: :created_at_start_link_time,
             programmed_responses: []]

  runs_in_sender do
    def start_link(keys) do
      GenServer.start_link(__MODULE__, keys)
    end

    def send_spontaneous_affordance(pid, [{affordance_name, data}]) do
      GenServer.cast(pid, {:affordance, affordance_name, data})
      pid
    end

    def program_focus_response(pid, affordance_name, response_generator) do
      GenServer.cast(pid, {:add_programmed_response, affordance_name, response_generator})
      pid
    end

    def send_focus_affordance(pid, affordance_name) do
      GenServer.cast(pid, {:affordance_request, affordance_name})
      pid
    end
  end

  runs_in_receiver do
    def init(keys) do
      {:ok, struct(__MODULE__, keys)}
    end

    def handle_cast({:affordance, affordance_name, data}, mutable) do
      Neural.Switchboard.forward_affordance(mutable.switchboard,
                                            named: affordance_name, conveying: data)
      continue(mutable)
    end

    def handle_cast({:add_programmed_response, affordance_name, response_generator},
                    mutable) do
      mutable
      |> Map.update!(:programmed_responses,
                    &(&1 ++ [{affordance_name, response_generator}]))
      |> continue()
    end

    def handle_cast({:affordance_request, affordance_name}, mutable) do
      {handler, remaining_responses} =
        Keyword.pop_first(mutable.programmed_responses, affordance_name)

      handle_cast({:affordance, affordance_name, handler.()}, mutable)

      mutable
      |> Map.put(:programmed_responses, remaining_responses)
      |> continue()
    end
  end
  
end
