defmodule AppAnimal.TestHelpers.MessageHelpers do

  defmacro assert_receive_cast(thing_being_cast) do
    quote do
      assert_receive({:"$gen_cast", unquote(thing_being_cast)})
    end
  end
end
