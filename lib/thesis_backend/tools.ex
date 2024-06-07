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
end
