require Logger

defmodule Servy.Handler do
  def handle(request) do
    request
    |> parse
    |> rewrite_path
    |> log
    |> route
    |> emojify
    |> track
    |> format_response
  end
  def track(%{ status: 404, path: path } = conv) do
    Logger.warn "Warning: #{path} is on the loose!"
    %{ conv | status: 404 }
  end

  def track(conv), do: conv
  def parse(request) do
    [method, path, _] = request
      |> String.split("\n")
      |> List.first
      |> String.split(" ")

    %{
      method: method,
      status: nil,
      path: path,
      resp_body: ""
    }
  end

  def rewrite_path(%{ path: "/wildlife" } = conv) do
    %{ conv | path: "/wildthings"}
  end

  def rewrite_path(%{path: path} = conv) do
    regex = ~r{\/(?<thing>\w+)\?id=(?<id>\d+)}
    captures = Regex.named_captures(regex, path)
    rewrite_path_captures(conv, captures)
  end

  def rewrite_path(conv), do: conv

  def rewrite_path_captures(conv, %{"thing" => thing, "id" => id}) do
    %{ conv | path: "/#{thing}/#{id}" }
  end

  def rewrite_path_captures(conv, nil), do: conv

  def log(conv), do: IO.inspect conv

  def route(%{ path: "/wildthings", method: "GET" } = conv) do
    %{ conv | status: 200, resp_body: "Bears, Lions, Tigers"}
  end

  def route(%{ path: "/bears", method: "GET" } = conv) do
    %{ conv | status: 200, resp_body: "Jurema, Juçara, Jandira"}
  end

  def route(%{ path: "/bears/" <> id , method: "GET" } = conv) do
    %{ conv | status: 200, resp_body: "You found out the bear ##{id}"}
  end

  def route(%{ method: "DELETE" } = conv) do
    %{ conv | status: 403, resp_body: "Wildlife cannot be deleted"}
  end

  def route(%{ path: path } = conv) do
    %{ conv | status: 404, path: path, resp_body: "There is no #{path} here"}
  end

  def format_response(conv) do
    """
    HTTP/1.1 #{conv.status} #{status_reason(conv.status)}
    Content-Type: text/html
    Content-Length: #{byte_size(conv.resp_body)}

    #{conv.resp_body}
    """
  end

  defp status_reason(code) do
    %{
      200 => "OK",
      201 => "Created",
      401 => "Unauthorized",
      403 => "Forbidden",
      404 => "Not Found",
      500 => "Internal Server Error"
    }[code]
  end

  def emojify(%{ status: 200} = conv) do
    emojies = String.duplicate("🎉", 5)
    body = emojies <> "\n" <> conv.resp_body <> "\n" <> emojies

    %{ conv | resp_body: body}
  end

  def emojify(conv), do: conv
end

request = """
GET /bears2?id=1 HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle(request)

IO.puts response
