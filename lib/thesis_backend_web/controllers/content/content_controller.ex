defmodule ThesisBackendWeb.Api.ContentController do
  use ThesisBackendWeb, :controller

  alias ThesisBackend.{AwsS3, Tools}
  alias ThesisBackend.Repo

  def upload_base64(_conn, params) do
    case AwsS3.upload_from_base64(params) do
      {:ok, url} ->
        {:success, :with_data, url}

      _ ->
        {:failed, :with_reason, "Bad Request!"}
    end
  end

  def upload_file(conn, %{"file" => file} = params) do
    with {:ok, content_url} <- AwsS3.upload_file(file) do
      {:success, :with_data, "content_url", content_url}
    else
      _ -> {:failed, :with_reason, "Bad Request!"}
    end
  end
end
