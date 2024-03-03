## Used to configure Logger. See root/config/config.exs

defmodule AppAnimal.Pretty.LogFormat do
  alias AppAnimal.Pretty
  use Private
  
  def format(_level, message, _timestamp, metadata) do
    message = format(message, metadata)
    source_description = format_name(metadata)
    [spacing_before(source_description), source_description, "  ", message, "\n"]
  end

  def spacing_before(source_description) do
    name_length = String.length(source_description)
    known_value = Application.get_env(:logger, :longest_prefix_so_far, 16)
    current_value = max(known_value, name_length)
    Application.put_env(:logger, :longest_prefix_so_far, current_value)
    String.duplicate(" ", current_value - name_length)
  end

  private do

    def format_name(metadata) do
      case Keyword.get(metadata, :cluster) do
        {cluster_type, cluster_name} ->
          "#{module_format(cluster_type)} #{cluster_name}"
        _ ->
          {module, _function, _arity} = Keyword.get(metadata, :mfa)
          module_format(module)
      end
    end

    def module_format(module) do
      Pretty.Module.terse(module) |> Macro.underscore
    end

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
