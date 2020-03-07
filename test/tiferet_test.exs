defmodule TiferetTest do
  use ExUnit.Case

  import Tiferet

  defmodule Encoder do
    @callback encode!(term) :: binary
  end

  defmodule MapEncoder do
    @behaviour Encoder

    def encode!(%{__struct__: _} = struct) do
      Map.drop(struct, [:__struct__])
    end
  end

  defpmodule Person, [encoder: Encoder, formatter: 1] do
    defstruct [:name]

    def speak(%__MODULE__{name: name}, message) do
      "#{name}: #{formatter().(message)}"
    end

    def encode!(%__MODULE__{} = person) do
      encoder().encode!(person)
    end
  end

  definst(Person, LoudPerson, encoder: MapEncoder, formatter: fn s -> String.upcase(s) end)
  definst(Person, QuietPerson, encoder: MapEncoder, formatter: fn s -> String.downcase(s) end)

  test "parameterized modules are generated" do
    loud_person = %LoudPerson{name: "Joe"}
    quiet_person = %QuietPerson{name: "Mike"}

    assert "Joe: HELLO MIKE" == LoudPerson.speak(loud_person, "hello mike")
    assert %{name: "Joe"} == LoudPerson.encode!(loud_person)

    assert "Mike: hello joe" == QuietPerson.speak(quiet_person, "HELLO JOE")
    assert %{name: "Mike"} == QuietPerson.encode!(quiet_person)
  end
end
