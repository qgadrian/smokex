defmodule Smokex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Smokex.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Smokex.PubSub}
      # Start a worker by calling: Smokex.Worker.start_link(arg)
      # {Smokex.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Smokex.Supervisor)
  end
end
