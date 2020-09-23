defmodule SmokexWeb.Controllers.WorkflowTest.TestEndpoint do
  use SmokexWeb, :controller

  require Logger

  @test_session_token "amazingsessiontokentotestaround"

  def login(conn, %{"user" => "smokex", "password" => "may the force be with you"}) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, "{\"session_token\": \"#{@test_session_token}\"}")
  end

  def login(conn, params) do
    Logger.debug(inspect(params))

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(402, "{}")
  end

  def get_players(conn, _params) do
    case get_req_header(conn, "auth") do
      [@test_session_token] ->
        players = %{
          "players" => [
            %{"name" => "Michael", "last_name" => "Jordan", "number" => 23},
            %{"name" => "LeBron", "last_name" => "James", "number" => 23},
            %{"name" => "Kobe", "last_name" => "Bryant", "number" => 24}
          ]
        }

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(players))

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(402, "{}")
    end
  end

  def best_laker(conn, %{"team" => "lakers", "number" => number}) do
    case {get_req_header(conn, "auth"), number} do
      {[@test_session_token], "24"} ->
        response = %{"best_laker" => true}
        send_resp(conn, 200, Jason.encode!(response))

      {[@test_session_token], _} ->
        response = %{"best_laker" => false}
        send_resp(conn, 200, Jason.encode!(response))

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(402, "{}")
    end
  end

  def message(conn, %{"message" => message, "number" => number}) do
    case {get_req_header(conn, "auth"), number} do
      {[@test_session_token], number} ->
        response = %{"response" => "your message was sent to player #{number}"}
        send_resp(conn, 200, Jason.encode!(response))

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(402, "{}")
    end
  end
end
