defmodule ThesisBackend.CustomEcto do
  defmacro ilike_search(column, term) do
    quote do
      fragment(
        "vietnamese_unaccent(lower(?)) like vietnamese_unaccent(lower(?))",
        unquote(column),
        ^"%#{unquote(term)}%"
      )
    end
  end

  defmacro ilike_search_lower(column, term) do
    quote do
      fragment(
        "lower(?) like lower(?)",
        unquote(column),
        ^"%#{unquote(term)}%"
      )
    end
  end

  defmacro tsvector_search(column, term) do
    quote do
      fragment(
        "to_tsvector('english', lower(?)) @@ plainto_tsquery('english', ?)",
        unquote(column),
        ^unquote(term)
      )
     end
  end

  defmacro get_jsonb_value(column, key) do
    quote do
      fragment("?::jsonb ->> ?", unquote(column), unquote(key))
    end
  end

  defmacro search_order_text(schema, term) do
    quote do
      ilike_search_lower(unquote(schema).bill_phone_number, unquote(term)) or
      ilike_search_lower(unquote(schema).bill_full_name, unquote(term)) or
        tsvector_search(unquote(schema).bill_full_name, unquote(term)) or
        tsvector_search(
          get_jsonb_value(unquote(schema).shipping_address, "full_address"),
          unquote(term)
        ) or
        ilike_search_lower(
          get_jsonb_value(unquote(schema).shipping_address, "full_address"),
          unquote(term)
        ) or
        ilike_search_lower(unquote(schema).aff, unquote(term))
    end
  end

  defmacro search_order_int(schema, term) do
    quote do
      search_order_text(unquote(schema), unquote(term)) or
      unquote(schema).display_id == ^unquote(term) or
      unquote(schema).id == ^unquote(term)
    end
  end

  defmacro search_order_uuid(schema, term) do
    quote do
      unquote(schema).id == ^unquote(term)
    end
  end
end
