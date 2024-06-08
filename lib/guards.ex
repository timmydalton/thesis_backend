defmodule ThesisBackend.Guards do
  defmacro is_empty(value) do
    quote do
      unquote(value) in [nil, "", "null", "undefined", "", [], %{}]
    end
  end
end
