defmodule Helix.Test.PropertyTest do
  use ExUnit.Case
  alias Helix.Builder.Property

  test "changeset single-link fields" do
    changeset =
      Property.changeset(%Property{
        name: "any",
        type: :single_link,
        link_class_id: nil
      })

    refute changeset.valid?

    changeset =
      Property.changeset(%Property{
        name: "any",
        type: :single_link,
        link_class_id: 0
      })

    refute changeset.valid?

    changeset =
      Property.changeset(%Property{
        name: "any",
        type: :single_link,
        link_class_id: 1
      })

    assert changeset.valid?
  end

  test "changeset multiple-link fields" do
    changeset =
      Property.changeset(%Property{
        name: "any",
        type: :multiple_link,
        link_class_id: nil
      })

    refute changeset.valid?

    changeset =
      Property.changeset(%Property{
        name: "any",
        type: :multiple_link,
        link_class_id: 0
      })

    refute changeset.valid?

    changeset =
      Property.changeset(%Property{
        name: "any",
        type: :multiple_link,
        link_class_id: 1
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
end
