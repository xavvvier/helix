defmodule Mix.Tasks.SystemSass do
  @moduledoc """
  Invokes sass with the given args.

  Usage:

      $ mix system_sass TASK_OPTIONS PROFILE SASS_ARGS

  Example:

      $ mix system_sass default assets/css/app.scss priv/static/assets/app.css

  If sass is not installed, the mix tasks fails.
  Note the arguments given to this task will be appended
  to any configured arguments.

  ## Options

    * `--runtime-config` - load the runtime configuration
      before executing command

  """
  use Mix.Task

  @impl true
  def run(args) do
    switches = [runtime_config: :boolean]
    {opts, remaining_args} = OptionParser.parse_head!(args, switches: switches)

    if opts[:runtime_config] do
      Mix.Task.run("app.config")
    else
      Application.ensure_all_started(:system_sass)
    end

    Mix.Task.reenable("system_sass")
    do_run(remaining_args)
  end

  defp do_run([profile | args] = all) do
    case SystemSass.run(String.to_atom(profile), args) do
      0 -> :ok
      status -> Mix.raise("`mix system_sass #{Enum.join(all, " ")}` exited with #{status}")
    end
  end

  defp do_run([]) do
    Mix.raise("`mix system_sass` expects the profile as argument")
  end

end
