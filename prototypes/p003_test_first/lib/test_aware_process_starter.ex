defmodule AppAnimal.Extras.TestAwareProcessStarter do
  import ExUnit.Callbacks, only: [start_link_supervised!: 1]

  defmacro __using__(_opts)  do
    module = __MODULE__
    quote do
      require unquote(module) 
      import  unquote(module), only: [compatibly_start_link: 2,
                                      compatibly_start_link: 3]
    end
  end
  
  
  defmacro compatibly_start_link(module, initial_mutable_state) do
    quote do 
      Code.ensure_loaded(Mix)
      compatibly_start_link(Mix.env, unquote(module), unquote(initial_mutable_state))
    end
  end


  def compatibly_start_link(:test, module, initial_mutable_state) do
    start_link_supervised!({module, initial_mutable_state})
  end

  def compatibly_start_link(_, module, initial_mutable_state) do
    {:ok, pid} = GenServer.start_link(module, initial_mutable_state)
    pid
  end

end
