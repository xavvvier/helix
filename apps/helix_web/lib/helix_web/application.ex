defmodule HXWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      HXWeb.Telemetry,
      # Start the Endpoint (http/https)
      HXWeb.Endpoint
      # Start a worker by calling: HXWeb.Worker.start_link(arg)
      # {HXWeb.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HXWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    HXWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
