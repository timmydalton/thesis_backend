defmodule ThesisBackend.Tools do
  def is_empty?(val) when val in [nil, "null", "undefined", "", [], %{}, "[object Object]"],
    do: true

  def is_empty?(_), do: false

  def is_valid_uuid?(uuid) do
    String.match?(uuid, ~r/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
  end

  def is_integer?(term) do
    String.match?(term, ~r/^-?\d+$/)
  end

  def to_int(el) when el in [nil, "", "null", "undefined", "", [], %{}], do: 0

  def to_int(el) when is_bitstring(el) do
    data =
      case Integer.parse(el) do
        {num, ""} -> num
        {num, _} -> num
        _ -> 0
      end

    data =
      case Ecto.UUID.cast(el) do
        {:ok, _} -> 0
        _ -> data
      end

    data
  end

  def to_int(el) when is_integer(el), do: el
  def to_int(_), do: 0

  def get_page_limit_from_params(params) do
    page = if !is_empty?(params["page"]), do: to_int(params["page"]), else: 1
    limit = if !is_empty?(params["limit"]), do: to_int(params["limit"]), else: 15

    {page, limit}
  end

  def hash(body) do
    :crypto.hash(:sha256, body)
    |> Base.encode16()
    |> String.downcase()
  end

  def get_record(data) when is_list(data), do: {:ok, data}
  def get_record(nil), do: {:error, :entity_not_existed}
  def get_record(struct), do: {:ok, struct}

  def to_atom_keys_map(%DateTime{} = datetime), do: datetime
  def to_atom_keys_map(%NaiveDateTime{} = datetime), do: datetime
  def to_atom_keys_map(struct) when is_struct(struct), do: struct

  def to_atom_keys_map(string_map) when is_map(string_map),
    do:
      for(
        {k, v} <- string_map,
        into: %{},
        do: {if(is_atom(k), do: k, else: String.to_atom(k)), to_atom_keys_map(v)}
      )

  def to_atom_keys_map(list) when is_list(list),
    do: Enum.map(list, fn elem -> to_atom_keys_map(elem) end)

  def to_atom_keys_map(not_is_map), do: not_is_map

  def to_string_keys_map(atom_map) do
    atom_map =
      if Map.has_key?(atom_map, :__struct__), do: Map.from_struct(atom_map), else: atom_map

    to_string_keys_map(Map.to_list(atom_map), %{})
  end

  def to_string_keys_map([], result), do: result

  def to_string_keys_map([{k, v} | tail], result) do
    tmp_k = if is_atom(k), do: Atom.to_string(k), else: k

    result =
      case tmp_k do
        "__struct__" ->
          result

        "__" <> _ ->
          result

        _ ->
          v = if is_map(v), do: to_string_keys_map(v), else: v
          Map.put(result, tmp_k, v)
      end

    to_string_keys_map(tail, result)
  end

  def get_extension_from_link(link) do
    split =
      link
      |> URI.parse()
      |> Map.fetch!(:path)
      |> Path.basename()
      |> String.split(".")

    if length(split) <= 1, do: "jpg", else: List.last(split)
  end

  def get_content_type_from_extension(ext) do
    case ext do
      "png" -> "image/png"
      "jpg" -> "image/jpeg"
      "jpeg" -> "image/jpeg"
      "webp" -> "image/webp"
      "gif" -> "image/gif"
      "avif" -> "image/avif"
      "svg" -> "image/svg+xml"
      "mp4" -> "video/mp4"
    end
  end

  def replace_special_char(str, without_spec_char \\ false) do
    str =
      to_string(str)
      |> String.replace(~r/#{white_space_char_regex()}/, " ")
      |> String.downcase()
      |> String.replace(~r/à|á|ạ|ả|ã|â|ầ|ấ|ậ|ẩ|ẫ|ă|ằ|ắ|ặ|ẳ|ẵ/, "a")
      |> String.replace(~r/è|é|ẹ|ẻ|ẽ|ê|ề|ế|ệ|ể|ễ/, "e")
      |> String.replace(~r/ì|í|ị|ỉ|ĩ/, "i")
      |> String.replace(~r/ò|ó|ọ|ỏ|õ|ô|ồ|ố|ộ|ổ|ỗ|ơ|ờ|ớ|ợ|ở|ỡ/, "o")
      |> String.replace(~r/ù|ú|ụ|ủ|ũ|ư|ừ|ứ|ự|ử|ữ/, "u")
      |> String.replace(~r/ỳ|ý|ỵ|ỷ|ỹ/, "y")
      |> String.replace(~r/đ|ð/, "d")
    cond do
      without_spec_char -> str
      true -> String.replace(str, ~r/[^a-zA-Z0-9\/\-\,\s]/, "")
    end
  end

  defp white_space_char_regex do
    codes = [
      "\u0009", "\u000A", "\u000B", "\u000C", "\u000D", "\u0020", "\u0085", "\u00A0", "\u1680", "\u2000", "\u2001", "\u2002",
      "\u2003", "\u2004", "\u2005", "\u2006", "\u2007", "\u2008", "\u2009", "\u200A", "\u2028", "\u2029", "\u202F", "\u205F", "\u3000"
    ]

    ret = Enum.reduce(codes, "", fn code, acc ->
      [regex] = String.graphemes(code)
      if acc === "", do: regex, else: "#{acc}|#{regex}"
    end)
    "(#{ret})"
  end

  def get_error_message_from_changeset(changeset) when is_list(changeset) do
    Enum.map(changeset, &get_error_message_from_changeset(&1))
  end

  def get_error_message_from_changeset(changeset) do
    errors = changeset.errors

    Enum.reduce(errors, "", fn {field, {message, _}}, acc ->
      if is_empty?(acc) do
        "#{Atom.to_string(field)}: #{message}"
      else
        if is_empty?(message), do: acc, else: acc <> ",#{Atom.to_string(field)}: #{message}"
      end
    end)
  end

  def get_error_message_from_changeset(changeset, :not_get_key) when is_list(changeset) do
    Enum.map(changeset, &get_error_message_from_changeset(&1, :not_get_key))
  end

  def get_error_message_from_changeset(changeset, :not_get_key) do
    errors = changeset.errors

    Enum.reduce(errors, "", fn {_field, {message, _}}, acc ->
      if is_empty?(acc) do
        message
      else
        if is_empty?(message), do: acc, else: acc <> ",#{message}"
      end
    end)
  end

  def get_start_end_time(params, timezone) do
    start_time =
      case Jason.decode(params["start_time"] || "") do
        {:ok, value} -> value
        _ -> params["start_time"]
      end

    start_time =
      if start_time do
        {:ok, start_time, _} = DateTime.from_iso8601(start_time)

        start_time
        |> Timex.beginning_of_day()
        |> Timex.shift(minutes: -trunc(timezone * 60))
      else
        start_time
      end

    end_time =
      case Jason.decode(params["end_time"] || "") do
        {:ok, value} -> value
        _ -> params["end_time"]
      end

    end_time =
      if end_time do
        {:ok, end_time, _} = DateTime.from_iso8601(end_time)

        end_time
        |> Timex.end_of_day()
        |> Timex.shift(minutes: -trunc(timezone * 60))
      else
        end_time
      end

    {start_time, end_time}
  end

  def convert_result_query_insight(raw_query) do
    case Ecto.Adapters.SQL.query(ThesisBackend.Repo, raw_query) do
      {:ok, %Postgrex.Result{rows: rows, columns: columns}} ->
        rows
        |> Enum.map(fn row ->
          row
          |> Enum.with_index()
          |> Enum.reduce(%{}, fn {el, idx}, acc ->
            pattern = ~r/<<([\d,\s]+)>>/

            el =
              if is_bitstring(el) do
                str = Macro.to_string(el)

                if String.contains?(str, "<<") do
                  if Regex.match?(pattern, str) do
                    case Ecto.UUID.cast(el) do
                      {:ok, v} -> v
                      _ -> el
                    end
                  else
                    el
                  end
                else
                  el
                end
              else
                el
              end

            Map.put(acc, Enum.at(columns, idx), el)
          end)
        end)

      _ ->
        []
    end
  end
end
