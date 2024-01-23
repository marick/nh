defmodule AppAnimal.WithoutReply do
  def activate(task_module),
      do: activate_with_args(task_module, [])
  def activate(task_module, on: args) when is_list(args),
      do: activate_with_args(task_module, args)
  def activate(task_module, on: arg),
      do: activate_with_args(task_module, [arg])

  defp activate_with_args(module, args) do 
    runner = fn -> apply(module, :activate, args) end
    Task.async(runner)
  end
end
  
