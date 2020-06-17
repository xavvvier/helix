defmodule HX.Test.PropertyTest do
  use ExUnit.Case
  alias HX.Builder.Property

  test "changeset single-link fields" do
    changeset =
      Property.changeset(%Property{
        name: "any",
        type: :single_link,
        linked_class_id: nil
      })

    refute changeset.valid?

    changeset =
      Property.changeset(%Property{
        name: "any",
        type: :single_link,
        linked_class_id: 0
      })

    refute changeset.valid?

    changeset =
      Property.changeset(%Property{
        name: "any",
        type: :single_link,
        linked_class_id: 1
      })

    assert changeset.valid?
  end

  test "changeset multiple-link fields" do
    changeset =
      Property.changeset(%Property{
        name: "any",
        type: :multiple_link,
        linked_class_id: nil
      })

    refute changeset.valid?

    changeset =
      Property.changeset(%Property{
        name: "any",
        type: :multiple_link,
        linked_class_id: 0
      })

    refute changeset.valid?

    changeset =
      Property.changeset(%Property{
        name: "any",
        type: :multiple_link,
        linked_class_id: 1
      })

    assert changeset.valid?
  end

  test "changeset text field" do
    changeset =
      Property.changeset(%Property{
        name: "any",
        type: :text
      })

    refute changeset.valid?

    changeset =
      Property.changeset(%Property{
        name: "any",
        type: :text,
        length: 10
      })

    assert changeset.valid?
  end

  test "changeset decimal field" do
    changeset =
      Property.changeset(%Property{
        name: "any",
        type: :decimal
      })

    refute changeset.valid?

    changeset =
      Property.changeset(%Property{
        name: "any",
        type: :decimal,
        precision: 1
      })

    refute changeset.valid?

    changeset =
      Property.changeset(%Property{
        name: "any",
        type: :decimal,
        scale: 1
      })

    refute changeset.valid?

    changeset =
      Property.changeset(%Property{
        name: "any",
        type: :decimal,
        precision: 8,
        scale: 2
      })

    assert changeset.valid?
  end

  defp build_prop(type, length, precision, scale, nullable) do
    %Property{type: type, length: length, precision: precision, scale: scale, nullable: nullable}
    |> Property.ecto_type()
  end

  test "ecto_type from atoms" do
    result =
      ~w(number big_number date time datetime big_text yes_no file single_link single_option)a
      |> Enum.map(&build_prop(&1, nil, nil, nil, nil))
      |> Enum.map(&elem(&1, 0))

    assert result == ~w[integer bigint date time timestamp text boolean string integer integer]a
    assert build_prop(:text, 10, nil, nil, nil) == {:string, size: 10, null: nil}
    assert build_prop(:text, 10, 0, nil, nil) == {:string, size: 10, null: nil}

    assert build_prop(:decimal, nil, 7, 3, nil) ==
             {:numeric, precision: 7, scale: 3, null: nil}
  end

  test "ecto_type text without length should fail" do
    assert_raise ArgumentError, "invalid text length", fn ->
      build_prop(:text, 0, nil, nil, nil)
    end

    assert_raise ArgumentError, "invalid text length", fn ->
      build_prop(:text, -1, nil, nil, nil)
    end

    assert_raise ArgumentError, "invalid text length", fn ->
      build_prop(:text, "nope", nil, nil, nil)
    end
  end

  test "ecto_type decimal without precision or scale should fail" do
    assert_raise ArgumentError, "invalid decimal precision/scale", fn ->
      build_prop(:decimal, nil, 0, 2, nil)
    end

    assert_raise ArgumentError, "invalid decimal precision/scale", fn ->
      build_prop(:decimal, nil, -1, 2, nil)
    end

    assert_raise ArgumentError, "invalid decimal precision/scale", fn ->
      build_prop(:decimal, nil, "nope", 2, nil)
    end

    assert_raise ArgumentError, "invalid decimal precision/scale", fn ->
      build_prop(:decimal, nil, 5, 0, nil)
    end

    assert_raise ArgumentError, "invalid decimal precision/scale", fn ->
      build_prop(:decimal, nil, 5, -1, nil)
    end

    assert_raise ArgumentError, "invalid decimal precision/scale", fn ->
      build_prop(:decimal, nil, 5, "nope", nil)
    end
  end

  test "ecto_type raise error when argument is not atom" do
    assert_raise RuntimeError, fn ->
      build_prop("not_atom", nil, nil, nil, nil)
    end
  end
end
