## Used to configure Logger. See root/config/config.exs

defmodule MyFormat do
  alias AppAnimal.Pretty
  use Private
  
  def format(_level, message, _timestamp, metadata) do
    message = format(message, metadata)
    {module, _function, _arity} = Keyword.get(metadata, :mfa)
    module_name = Pretty.Module.terse(module) |> Macro.underscore
    [spacing_before(module_name), module_name, "  ", message, "\n"]
  end

  def spacing_before(module_name) do
    name_length = String.length(module_name)
    known_value = Application.get_env(:logger, :longest_prefix_so_far, 16)
    current_value = max(known_value, name_length)
    Application.put_env(:logger, :longest_prefix_so_far, current_value)
    String.duplicate(" ", current_value - name_length)
  end

  private do

    def format(message, metadata) do
      message
      |> handle_newlines(metadata)
    end

    def handle_newlines(message, metadata) do
      if Keyword.get(metadata, :newlines) == :visible do
        String.replace(message, "\n", "\\n")  
      else
        message
      end
    end
  end
end
