defmodule Helix.Test.PropertyTypeTest do
  use ExUnit.Case, async: true
  alias Helix.Builder.PropertyType
  doctest PropertyType

  test "to_integer from atoms" do
    result =
      ~w(number big_number date time datetime text big_text decimal yes_no file multiple_file single_link multiple_link single_select multiple_select)a
      |> Enum.map(&PropertyType.to_integer/1)
    assert result == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
  end

  test "to_integer fails when argument is not atom" do
    assert_raise RuntimeError, fn ->
      PropertyType.to_integer("not_atom")
    end
  end

  test "to_atom from integers" do
    result =
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
      |> Enum.map(&PropertyType.to_atom/1)
    assert result == ~w(number big_number date time datetime text big_text decimal yes_no file multiple_file single_link multiple_link single_select multiple_select)a
  end

  test "to_atom fails when argument is not integer" do
    assert_raise RuntimeError, fn ->
      PropertyType.to_atom("not_atom")
    end
  end

end
