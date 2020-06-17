defmodule HX.Builder do
  use GenServer
  alias HX.Builder.{Impl, Class, ClassIdentifier, Property}

  @server __MODULE__

  @moduledoc """
  Creates `Class` and `Property` in the system
  """

  ## API

  def start_link(state) do
    GenServer.start_link(@server, state, name: @server)
  end

  @doc """
  Creates a `Class` and the given properties.
  Every `Class` creates an id `Property` by default.
  """
  @spec create_class(Class.t()) :: {:ok, map()} | {:error, atom(), tuple()}
  def create_class(%Class{} = class) do
    GenServer.call(@server, {:create_class, class})
  end

  @doc """
  Add `Property` elements to an existent class, use the `ClassIdentifier` to locate the `Class`
  """
  @spec create_properties(ClassIdentifier.t(), [Property.t()]) ::
          {:ok, map()} | {:error, atom(), any()}
  def create_properties(%ClassIdentifier{} = class, properties) do
    GenServer.call(@server, {:create_properties, class, properties})
  end

  ## GenServer implementation

  def init(state) do
    {:ok, state}
  end

  def handle_call({:create_class, class}, _from, state) do
    {:reply, Impl.create_class(class), state}
  end

  def handle_call({:create_properties, class, properties}, _from, state) do
    {:reply, Impl.create_properties(class, properties), state}
  end
end