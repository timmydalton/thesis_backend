defmodule ThesisBackend.Parse do
  alias ThesisBackend.{Tools}

  def sort_items(items) do
    case items do
      nil -> []
      ""  -> []
      items when is_list(items) ->
        Enum.map(items, fn item ->
          case item do
            {_, item} -> item
            item -> item
          end
        end)
      items when is_map(items) ->
        Enum.sort_by(items, fn {key, _value} ->
          if is_bitstring(key) && !String.match?(key, ~r/\D/),
            do: integer(key),
            else: 0
        end)
        |> Enum.map(& elem(&1, 1))
    end
  end

  def formdata_array(data) when is_map(data) do
    sort_items(data)
  end
  def formdata_array("-1"), do: []
  def formdata_array(-1), do: []
  def formdata_array(nil), do: []
  def formdata_array(""), do: []
  def formdata_array("undefined"), do: []
  def formdata_array(data) when is_list(data) do
    Enum.map(data, fn ele ->
      case ele do
        {_, value} -> value
        value -> value
      end
    end)
  end
  def formdata_array(data), do: data

  def struct_to_map(struct, drop_keys \\ [])
  def struct_to_map(nil, _), do: nil
  def struct_to_map({:ok, struct}, drop_keys), do: {:ok, struct_to_map(struct, drop_keys)}
  def struct_to_map({:error, _} = error, _), do: error
  def struct_to_map(struct, drop_keys) when is_list(struct), do: Enum.map(struct, &struct_to_map(&1, drop_keys))
  def struct_to_map(struct, drop_keys), do: Map.drop(struct, [:__meta__, :__struct__] ++ drop_keys)

  def boolean("true"), do: true
  def boolean(input) when is_boolean(input), do: input
  def boolean(nil), do: false
  def boolean(_), do: false

  def integer("NULL"), do: 0
  def integer("NaN"), do: 0
  def integer("undefined"), do: 0
  def integer(""), do: 0
  def integer(nil), do: 0
  def integer(input) when is_float(input), do: round(input)
  def integer(input) when is_binary(input), do: String.trim(input) |> String.to_integer()
  def integer(input) when is_integer(input), do: input

  def float("NULL"), do: 0.0
  def float(nil), do: 0.0
  def float("undefined"), do: 0.0
  def float(".0"), do: 0.0
  def float(input) when is_binary(input) do
    if String.contains?(input, "."),
      do: String.to_float(input),
      else: String.to_float("#{input}.0")
  end
  def float(input) when is_integer(input), do: String.to_float("#{input}.0")
  def float(input) when is_float(input), do: input

  def string(input) when is_integer(input), do: Integer.to_string(input)
  def string(input) when is_float(input), do: Float.to_string(input)
  def string(input) when is_binary(input), do: input

  def word_count(string),
  do:
    string
    |> String.replace("-", " ")
    |> String.split(" ")
    |> Enum.filter(&(&1 != ""))
    |> length()

  def arr_to_string(arr), do: Enum.join(arr, " ") |> Tools.replace_special_char(true)
end
