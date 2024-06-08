defmodule ThesisBackend.Request do
  @default_msg "Cannot perform request"
  @timeout 20000

  require Logger
  alias ThesisBackend.{Tools}

  def rq_get(url, headers \\ [], err_msg \\ @default_msg) do
    HTTPoison.get(
      url,
      headers,
      recv_timeout: @timeout
    )
    |> response(url, err_msg)
  end

  def rq_post(url, body, headers \\ [], err_msg \\ @default_msg) do
    HTTPoison.post(
      url,
      body,
      headers,
      recv_timeout: @timeout
    )
    |> response(url, err_msg)
  end

  def rq_delete(url, headers \\ [], err_msg \\ @default_msg) do
    HTTPoison.delete(url, headers, recv_timeout: 20000)
    |> response(url, err_msg)
  end

  def rq_json_get(url, data \\ %{}, headers \\ [], err_msg \\ @default_msg) do
    body = Jason.encode!(data)

    ssl_option =
      if String.contains?(url, "https://pos-host") ||
           String.contains?(url, "https://pos.pages.fm/api/v1/webcms") do
        [ssl: [{:versions, [:"tlsv1.2"]}]]
      else
        []
      end

    HTTPoison.get(
      url,
      [{"Content-Type", "application/json"}] ++ headers,
      [recv_timeout: 20000, body: body] ++ ssl_option
    )
    |> response(url, err_msg)
  end

  def rq_json_post(url, data \\ %{}, headers \\ [], err_msg \\ @default_msg) do
    body = Jason.encode!(data)

    ssl_option =
      if String.contains?(url, "https://pos-host") || String.contains?(url, "https://web") ||
           String.contains?(url, "https://pos.pages.fm/api/v1/webcms") do
        [ssl: [{:versions, [:"tlsv1.2"]}]]
      else
        []
      end

    HTTPoison.post(
      url,
      body,
      [{"Content-Type", "application/json"}] ++ headers,
      [recv_timeout: 20000] ++ ssl_option
    )
    |> response(url, err_msg)
  end

  # body: [{"key", "value"}, {"key1", "value1"}]
  def rq_post_multipart(url, body, headers \\ [], err_msg \\ @default_msg) do
    body = {:multipart, body}

    headers = [{"Content-Type", "multipart/form-data"}] ++ headers

    HTTPoison.post(
      url,
      body,
      headers,
      recv_timeout: @timeout
    )
    |> response(url, err_msg)
  end

  def rq_json_put(url, data \\ %{}, headers \\ [], err_msg \\ @default_msg) do
    body = Jason.encode!(data)

    HTTPoison.put(
      url,
      body,
      [{"Content-Type", "application/json"}] ++ headers,
      recv_timeout: 20000
    )
    |> response(url, err_msg)
  end

  def rq_json_post_timeout(url, data \\ %{}, timeout \\ 2000,headers \\ [], err_msg \\ @default_msg) do
    body = Jason.encode!(data)

    ssl_option =
      if String.contains?(url, "https://pos-host") || String.contains?(url, "https://web") ||
           String.contains?(url, "https://pos.pages.fm/api/v1/webcms") do
        [ssl: [{:versions, [:"tlsv1.2"]}]]
      else
        []
      end

    HTTPoison.post(
      url,
      body,
      [{"Content-Type", "application/json"}] ++ headers,
      [recv_timeout: timeout] ++ ssl_option
    )
    |> response(url, err_msg)
  end

  def response(response, url, err_msg) do
    case response do
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        success = status >= 200 && status <= 300

        try do
          body = if Tools.is_empty?(body), do: "{}", else: body
          body = Jason.decode!(body)
          %{"success" => success, "body" => body, "status_code" => status}
        rescue
          _ ->
            %{"success" => success, "body" => body, "status_code" => status}
        end

      {:error, %HTTPoison.Error{id: nil, reason: {:tls_alert, {:unexpected_message, message}}}} ->
        Logger.error("Error from #{url}: #{message}")
        %{"success" => false, "reason" => message, "message" => err_msg}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Error from #{url}: #{reason}")
        %{"success" => false, "reason" => reason, "message" => err_msg}
    end
  end
end
