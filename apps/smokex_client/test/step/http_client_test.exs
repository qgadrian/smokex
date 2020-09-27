defmodule SmokexClient.Step.HttpClientTest do
  use ExUnit.Case, aync: true

  import ExUnit.CaptureLog
  import Smokex.TestSupport.Factories

  alias SmokexClient.Step.HttpClient

  describe "new/1" do
    test "builds a Tesla client with the default opts" do
      request = build(:request)

      assert %Tesla.Client{
               adapter: {Tesla.Adapter.Hackney, _, [[insecure: true, recv_timeout: 5000]]},
               pre: [
                 {Tesla.Middleware.JSON, _, _},
                 {Tesla.Middleware.Query, _, _},
                 {Tesla.Middleware.Headers, _, _},
                 {Tesla.Middleware.Timeout, _, [[timeout: 5000]]},
                 {Tesla.Middleware.Retry, _, [[max_retries: 0]]},
                 {Tesla.Middleware.Telemetry, _, _}
               ],
               post: []
             } = HttpClient.new(request)
    end

    test "builds a Tesla client with the request opts" do
      request = build(:request, opts: [timeout: 23, retries: 5])

      assert %Tesla.Client{
               adapter: {Tesla.Adapter.Hackney, _, [[insecure: true, recv_timeout: 23]]},
               pre: [
                 {Tesla.Middleware.JSON, _, _},
                 {Tesla.Middleware.Query, _, _},
                 {Tesla.Middleware.Headers, _, _},
                 {Tesla.Middleware.Timeout, _, [[timeout: 23]]},
                 {Tesla.Middleware.Retry, _, [[max_retries: 5]]},
                 {Tesla.Middleware.Telemetry, _, _}
               ],
               post: []
             } = HttpClient.new(request)
    end
  end

  describe "request/1" do
    test "returns the request context when the request got a response" do
      request = build(:request, host: "https://localhost:5743/get")

      assert {:ok, %Tesla.Env{status: 200, url: "https://localhost:5743/get"}} =
               HttpClient.request(request)
    end

    test "returns the error if the request connection failed" do
      request = build(:request, host: "localhost")

      assert {:error, :econnrefused} = HttpClient.request(request)
    end

    test "if debug option is present the request is logged" do
      request = build(:request, host: "https://localhost:5743/get", opts: [debug: true])

      assert capture_log(fn ->
               HttpClient.request(request)
             end) =~ "Request context: %Tesla.Env{"
    end

    test "if debug option is present if the request fails the error is logged" do
      request = build(:request, host: "localhost", opts: [debug: true])

      assert capture_log(fn ->
               HttpClient.request(request)
             end) =~ "Request failed: :econnrefused"
    end
  end
end
