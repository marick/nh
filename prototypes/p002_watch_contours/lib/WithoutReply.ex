defmodule AppAnimal.WithoutReply do
  def activate(task_module),
      do: activate_with_args(task_module, [])
  def activate(task_module, on_one: arg),
      do: activate_with_args(task_module, [arg])

  defp activate_with_args(module, parameter_list) do
    runner = fn -> apply(module, :activate, parameter_list) end
    Task.async(runner)
  end
end
  
