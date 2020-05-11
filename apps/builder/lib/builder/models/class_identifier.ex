defmodule Helix.Builder.ClassIdentifier do
  @moduledoc """
  Identifies a `Class` by id, name or GUID.
  Currently only id is supported
  """
  defstruct id: 0

  @typedoc """
    Type to represent the `ClassIdentifier` struct with id as an integer
  """
  @type t :: %__MODULE__{id: pos_integer()}

end
