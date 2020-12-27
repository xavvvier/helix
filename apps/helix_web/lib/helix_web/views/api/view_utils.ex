defmodule HXWeb.ViewUtils do
  @moduledoc """
  Utility functions
  """

  @doc """
  A handy function to hide a HTML element conditionally
  Returns "hide" if `value` is not equal to `expected` or if
  `value` is not in the `options` list
  """
  def visible_when(value, options) when is_list(options) do
    if value in options, do: "", else: "hide"
  end
  def visible_when(value, expected) when value == expected, do: ""
  def visible_when(_value, _other), do: "hide"

end
