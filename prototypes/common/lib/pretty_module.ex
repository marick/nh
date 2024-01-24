defmodule AppAnimal.PrettyModule do
  use Private
  
  def terse(arg) when is_atom(arg),
      do: split_module_name(arg) |> Enum.slice(-2..-1) |> Enum.join(".")
  def terse(args) when is_list(args),
      do: run_to_make_list(&terse/1, args)
  
  def minimal(arg) when is_atom(arg),
      do: split_module_name(arg) |> List.last
  def minimal(args) when is_list(args),
      do: run_to_make_list(&minimal/1, args)

  private do
    def split_module_name(arg), do: inspect(arg) |> String.split(".")
    
    def run_to_make_list(f, args) do
      args
      |> Enum.map(f)
      |> inspect
      |> String.replace(~s/"/, ~s//)
    end
  end
end
