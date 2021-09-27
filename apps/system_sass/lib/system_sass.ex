defmodule SystemSass do
  @moduledoc """
  SystemSass is a runner for [sass](https://sass-lang.com/).

  ## Profiles

  You can define multiple profiles. By default, there is a
  profile called `:default` which you can configure its args, current
  directory and environment:

      config :system_sass,
        default: [
          args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
          cd: Path.expand("../assets", __DIR__),
          env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
        ]
  """

  use Application
  require Logger

  @sass_process "sass"

  @doc false
  def start(_, _) do
    unless is_sass_installed?() do
      Logger.warn("#{@sass_process} not detected in the machine.")
    end

    Supervisor.start_link([], strategy: :one_for_one)
  end

  @doc """
  Runs the `sass` command with `args`.

  The given args will be appended to the configured args.
  The task output will be streamed directly to stdio. It
  returns the status of the underlying call.
  """
  def run(profile, extra_args) when is_atom(profile) and is_list(extra_args) do
    config = config_for!(profile)
    args = config[:args] || []

    opts = [
      cd: config[:cd] || File.cwd!(),
      into: IO.stream(:stdio, :line),
      stderr_to_stdout: true
    ]

    bin_path()
    |> System.cmd(args ++ extra_args, opts)
    |> elem(1)
  end

  defp is_sass_installed?() do
    case System.cmd("which", [@sass_process]) do
      {_, 0} -> true
      {_, _} -> false
    end
  end

  defp bin_path() do
    if is_sass_installed?() do
      @sass_process
    else
      raise "Unable to find sass in the system"
    end
  end

  @doc """
  Returns the configuration for the given profile.

  Returns nil if the profile does not exist.
  """
  def config_for!(profile) when is_atom(profile) do
    Application.get_env(:system_sass, profile) ||
      raise ArgumentError, """
      unknown system_sass profile. Make sure the profile is defined in your config/config.exs file, such as:

          config :system_sass,
            #{profile}: [
              args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
              cd: Path.expand("../assets", __DIR__),
              env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
            ]
      """
  end


end
