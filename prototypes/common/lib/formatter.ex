defmodule MyFormat do
  alias AppAnimal.PrettyModule
  
  def format(_level, message, _timestamp, metadata) do
    {module, _function, _arity} = Keyword.get(metadata, :mfa)
    module_name = PrettyModule.terse(module) |> Macro.underscore
    [spacing_before(module_name), module_name, "  ", message, "\n"]
  end

  def spacing_before(module_name) do
    name_length = String.length(module_name)
    known_value = Application.get_env(:logger, :longest_prefix_so_far, 16)
    current_value = max(known_value, name_length)
    Application.put_env(:logger, :longest_prefix_so_far, current_value)
    String.duplicate(" ", current_value - name_length)
  end
end
