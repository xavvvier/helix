defmodule Helix.Test.SqlDefinitionTest do
  use ExUnit.Case, async: true
  alias Helix.Builder.SqlDefinition
  doctest Helix.Builder.SqlDefinition

  test "to_ecto_type from atoms" do
    result =
      ~w(number big_number date time datetime big_text yes_no file single_link single_select)a
      |> Enum.map(&(SqlDefinition.to_ecto_type(&1, nil, nil, nil, nil)))
      |> Enum.map(&elem(&1, 0))
    assert result == ~w[integer bigint date time timestamp text boolean binary integer integer]a
    assert SqlDefinition.to_ecto_type(:text, 10, nil, nil, nil) == {:string, size: 10, null: nil}
    assert SqlDefinition.to_ecto_type(:text, 10, 0, nil, nil) == {:string, size: 10, null: nil}
    assert SqlDefinition.to_ecto_type(:decimal, nil, 7, 3, nil) == {:numeric, precision: 7, scale: 3, null: nil}
  end

  test "to_ecto_type text without length should fail" do
    assert_raise ArgumentError, "invalid text length", fn ->
      SqlDefinition.to_ecto_type(:text, 0, nil, nil, nil)
    end
    assert_raise ArgumentError, "invalid text length", fn ->
      SqlDefinition.to_ecto_type(:text, -1, nil, nil, nil)
    end
    assert_raise ArgumentError, "invalid text length", fn ->
      SqlDefinition.to_ecto_type(:text, "nope", nil, nil, nil)
    end
  end

  test "to_ecto_type decimal without precision or scale should fail" do
    assert_raise ArgumentError, "invalid decimal precision/scale", fn ->
      SqlDefinition.to_ecto_type(:decimal, nil, 0, 2, nil)
    end
    assert_raise ArgumentError, "invalid decimal precision/scale", fn ->
      SqlDefinition.to_ecto_type(:decimal, nil, -1, 2, nil)
    end
    assert_raise ArgumentError, "invalid decimal precision/scale", fn ->
      SqlDefinition.to_ecto_type(:decimal, nil, "nope", 2, nil)
    end
    assert_raise ArgumentError, "invalid decimal precision/scale", fn ->
      SqlDefinition.to_ecto_type(:decimal, nil, 5, 0, nil)
    end
    assert_raise ArgumentError, "invalid decimal precision/scale", fn ->
      SqlDefinition.to_ecto_type(:decimal, nil, 5, -1, nil)
    end
    assert_raise ArgumentError, "invalid decimal precision/scale", fn ->
      SqlDefinition.to_ecto_type(:decimal, nil, 5, "nope", nil)
    end
  end

  test "to_ecto_type raise error when argument is not atom" do
    assert_raise RuntimeError, fn ->
      SqlDefinition.to_ecto_type("not_atom", nil, nil, nil, nil)
    end
  end

end
