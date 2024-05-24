defmodule ThesisBackendWeb.FallbackController do
  use ThesisBackendWeb, :controller

  def call(conn, {:success, :success_only}) do
    conn
    |> json(%{success: true, success_only: true})
  end

  def call(conn, {:success, :with_data, data}) do
    conn
    |> put_status(200)
    |> json(%{success: true, data: data, fallback: "with_data"})
  end

  def call(conn, {:success_vnpay, :with_msg, data}) do
    conn
    |> put_status(200)
    |> json(data)
  end

  def call(conn, {:success, :with_data, key, data}) do
    data =
      %{success: true, fallback: "with_data"}
      |> Map.put(String.to_atom("#{key}"), data)

    conn
    |> put_status(200)
    |> json(data)
  end

  def call(conn, {:failed, :with_reason, reason}) do
    conn
    |> put_status(422)
    |> json(%{success: false, reason: reason, fallback: "with_reason"})
  end

  def call(conn, {:failed, :with_code, code}) do
    conn
    |> put_status(422)
    |> json(%{success: false, code: code, fallback: "with_code"})
  end

  def call(conn, {:failed, :with_data_error, data, message}) do
    conn
    |> put_status(422)
    |> json(%{success: false, data: data, message: message, fallback: "with_data_error"})
  end
end
