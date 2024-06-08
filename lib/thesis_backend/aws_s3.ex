defmodule ThesisBackend.AwsS3 do
  alias ThesisBackend.{Tools, Request}

  def upload(_, _, "text/html"), do: {:error, :invalid_type}
  def upload(binary, _, _) when not is_binary(binary), do: {:error, :invalid_type}

  def upload(binary, ext, content_type) do
    bucket_name = if web_content

    hash_res = Tools.hash(binary)
    hash_chunks = for <<x::binary-2 <- hash_res>>, do: x

    [one, two, three, four | rest] = hash_chunks
    filename = Enum.join(rest, "")
    path_lookup = [one, two, three, four] |> Enum.join("/")

    object = "/#{path_lookup}/#{filename}.#{ext}"
    content_url = "https://content.pancake.vn/#{bucket_name}#{object}"

    ExAws.S3.head_object(bucket_name, object)
    |> ExAws.request()
    |> case do
      {:ok, %{status_code: 200}} ->
        {:ok, content_url}

      {:error, {:http_error, 404, _}} ->
        ExAws.S3.put_object(bucket_name, object, binary,
          acl: :public_read,
          content_type: content_type
        )
        |> ExAws.request()
        |> case do
          {:ok, _} -> {:ok, content_url}
          _ -> {:error, :cannot_upload}
        end

      _ ->
        {:error, :something_went_wrong}
    end
  end

  def upload_file(%Plug.Upload{} = file) do
    if file.content_type == "image/tiff" do
      convert(file)
    else
      case File.read(file.path) do
        {:ok, binary} ->
          [ext | _filename] = file.filename |> String.split(".") |> Enum.reverse()

          upload(binary, ext, file.content_type)

        _ ->
          {:error, :cannot_upload}
      end
    end
  end

  def upload_from_link(link) do
    binary =
      case Request.rq_get(link) do
        %{"success" => true, "body" => body} ->
          body

        _ ->
          nil
      end
    ext = Tools.get_extension_from_link(link)
    content_type = Tools.get_content_type_from_extension(ext)

    upload(binary, ext, content_type)
  end

  def get_thumbnail_from_video(%Plug.Upload{} = file) do
    case File.read(file.path) do
      {:ok, _binary} ->
        [_ext | filename] = file.filename |> String.split(".") |> Enum.reverse()

        Tmp.dir(
          fn path ->
            output = Path.join(path, "#{filename}.jpeg")

            System.cmd("ffmpeg", ["-i", file.path, "-ss", "00:00:00.000", "-vframes", "1", output])

            case File.read(output) do
              {:ok, binary} ->
                upload(binary, "jpeg", "image/jpeg")

              _ ->
                {:error, :invalid_type}
            end
          end,
          base_dir: "/tmp/tmp_video"
        )

      _ ->
        {:error, :cannot_upload}
    end
  end

  def upload_from_base64(%{"base64" => base64}) do
    with true <- Regex.match?(~r/data:image\/(jpe?g|png)/, base64) do
      [_, binary] = String.split(base64, ",")

      Base.decode64!(binary)
      |> upload("png", "image/png")
    else
      _ ->
        {:error, :something_went_wrong}
    end
  end

  def get_thumbnail_video_from_url(path) do
    Tmp.dir(
      fn tmp_dir_path ->
        ext = Path.extname(path)
        filename = Path.basename(path, ext)

        output = Path.join(tmp_dir_path, "#{filename}.jpeg")
        System.cmd("ffmpeg", ["-i", path, "-ss", "00:00:00.000", "-vframes", "1", output])

        case File.read(output) do
          {:ok, binary} ->
            upload(binary, "jpeg", "image/jpeg")

          _ ->
            {:error, :invalid_type}
        end
      end,
      base_dir: "/tmp/tmp_video"
    )

  end

  def convert(file) do
    case File.read(file.path) do
      {:ok, _binary} ->
        file_format =
          Mogrify.open(file.path)
          |> Mogrify.format("png")

        case File.read(file_format.path) do
          {:ok, binary} ->
            upload(binary, "png", "image/png")

          _ ->
            {:error, :invalid_type}
        end

      _ ->
        {:error, :cannot_upload}
    end
  end
end
