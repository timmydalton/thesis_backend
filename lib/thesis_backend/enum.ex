defmodule Enum.OrderStatus do
  status = [
    new: 0,
    submitted: 1,
    shipped: 2,
    delivered: 3,
    returning: 4,
    returned: 5,
    canceled: 6,
    removed: 7,
    packing: 8,
    pending: 9,
    waitting: 11,
    wait_print: 12,
    printed: 13,
    part_returned: 15,
    received_money: 16,
    wait_submit: 17,
    ordered: 20,
    draft: 22
  ]

  for {key, value} <- status do
    def value(unquote(key)), do: unquote(value)
    def which(unquote(value)), do: unquote(key)
  end

  def value(_), do: nil
  def which(_), do: nil
end
