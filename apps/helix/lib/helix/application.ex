defmodule HX.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      HX.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: HX.PubSub}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: HX.Supervisor)
  end
end
