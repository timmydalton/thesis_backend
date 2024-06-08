defmodule ThesisBackend.Variations do
  import Ecto.Query

  alias ThesisBackend.Variations.Variation
  alias ThesisBackend.{Repo, Parse, Tools}

  @field_variation [
    "fields",
    "custom_id",
    "remain_quantity",
    "retail_price",
    "original_price",
    "images",
    "is_hidden",
    "is_removed",
  ]

  def update_variation(%Variation{} = variation, attrs) do
    variation
    |> Variation.changeset(attrs)
    |> Repo.update()
  end

  def create_variation(attrs \\ %{}) do
    %Variation{}
    |> Variation.changeset(attrs)
    |> Repo.insert()
  end

  def create_or_update_variations(product, variations, spec) do
    product_id = product.id
    variations = sort_variations(variations, product)

    {success, error} =
      Enum.reduce(variations, {[], []}, fn el, acc ->
        {s, e} = acc

        if e == [] do
          case create_or_update_variation(product_id, el, spec) do
            {:ok, value} -> {s ++ [value], e}
            {:error, err} -> {s, e ++ [err]}
          end
        else
          acc
        end
      end)

    if length(error) == 0 do
      {:ok, success}
    else
      {:error, error}
    end
  end

  def create_or_update_variation(product_id, el, spec \\ nil) do
    if is_nil(el["id"]) do
      el =
        el
        |> Map.merge(%{
          "product_id" => product_id
        })

      %Variation{}
      |> Variation.changeset(el)
      |> Repo.insert()
    else
      variation = Repo.get_by(Variation, %{id: el["id"]})

      if !is_nil(variation) do
        variation
        |> Variation.changeset(el)
        |> Repo.update()
      end
    end
  end

  def sort_variations(variations, product) do
    data_variations =
      Enum.map(variations, fn variation_params ->
        variation_fields =
          case variation_params["fields"] do
            fields when is_map(fields) ->
              Map.values(fields)

            fields ->
              if fields == "-1", do: [], else: fields || []
          end

        product_attributes =
          if product.product_attributes,
            do: Parse.struct_to_map(product.product_attributes),
            else: []

        fields =
          if product_attributes != [] && variation_fields != [] do
            check_variation_field_by_product_attributes(
              Parse.struct_to_map(variation_fields),
              product_attributes
            )
          else
            []
          end

        variation_params =
          Map.merge(variation_params, %{
            "fields" => fields
          })
      end)
  end

  def parse_variation_sort_fields(variation_fields, product_attributes) do
    variation_fields = Enum.map(variation_fields, &Tools.to_atom_keys_map(&1))
    product_attributes = Enum.map(product_attributes, &Tools.to_atom_keys_map(&1))

    variation_fields =
      if length(variation_fields) > 1 do
        variation_fields
        |> Enum.sort(fn x, y ->
          Enum.find_index(product_attributes, fn i ->
            String.trim(i.name) == String.trim(x.name)
          end) <
            Enum.find_index(product_attributes, fn i ->
              String.trim(i.name) == String.trim(y.name)
            end)
        end)
      else
        variation_fields
      end

    product_attributes
    |> Enum.with_index()
    |> Enum.reduce("", fn {attribute, index}, acc ->
      idx_field =
        variation_fields
        |> Enum.find_index(fn f -> String.trim(f.name) == String.trim(attribute.name) end)

      index_name = if !is_nil(idx_field), do: index + 1, else: 0
      attribute_values = if attribute.values, do: attribute.values, else: []

      index_value =
        if !is_nil(idx_field) do
          check_index_value =
            attribute_values
            |> Enum.find_index(fn value -> value == Enum.at(variation_fields, idx_field).value end)

          if !is_nil(check_index_value) do
            check_index_value + 1
          else
            0
          end
        else
          0
        end

      index_value = if index_value < 10, do: "0" <> "#{index_value}", else: index_value
      acc <> "#{index_name}#{index_value}"
    end)
  end

  defp check_variation_field_by_product_attributes(variation_fields, product_attributes) do
    variation_fields = Enum.map(variation_fields, &Tools.to_atom_keys_map(&1))
    product_attributes = Enum.map(product_attributes, &Tools.to_atom_keys_map(&1))

    list_att_value =
      product_attributes
      |> Enum.reduce([], fn att, acc -> acc ++ att.values end)
      |> Enum.map(&String.trim(&1))

    list_att_name = Enum.map(product_attributes, &String.trim(&1.name))

    Enum.filter(variation_fields, fn field ->
      String.trim(field.name) in list_att_name && String.trim(field.value) in list_att_value
    end)
  end

  def get_variations_existed(product_id) do
    Variation
    |> where([v], v.product_id == ^product_id and not v.is_removed)
    |> select([v] , %{custom_id: v.custom_id})
    |> Repo.all()
  end

  def insert_all_vari_by_custom_id(data) do
    keys = if length(data) > 0, do: Map.keys(data |> hd()) -- [:id, :inserted_at], else: []

    Repo.insert_all(
      Variation,
      data
    )
    |> elem(0)

  end
end
