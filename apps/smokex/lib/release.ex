defmodule Smokex.Release do
  @moduledoc """
  Module that provides actions for release tasks.
  """

  @start_apps [:postgrex, :ecto, :ecto_sql]

  @app :smokex

  # https://elixirforum.com/t/how-to-create-database-on-release/28443/3
  def create_database do
    IO.puts("Starting dependencies...")

    Enum.each(@start_apps, &Application.ensure_all_started/1)

    for repo <- repos do
      :ok = ensure_repo_created(repo)
    end

    IO.puts("database created")
  end

  defp ensure_repo_created(repo) do
    IO.puts("create #{inspect(repo)} database if it doesn't exist")

    case repo.__adapter__.storage_up(repo.config) do
      :ok -> :ok
      {:error, :already_up} -> :ok
      {:error, term} -> {:error, term}
    end
  end

  def migrate do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
