defmodule AppAnimal.Neural.WithoutReply do
  def activate(task_module),
      do: activate_with_args(task_module, [])
  def activate(task_module, transmitting: arg),
      do: activate_with_args(task_module, [arg])

  defp activate_with_args(modules, parameter_list) when is_list(modules) do
    Enum.map(modules, &(activate_with_args &1, parameter_list))
  end

  defp activate_with_args(module, task) do
    runner = fn -> apply(module, :activate, task) end
    Task.async(runner)
  end
end
  
