defmodule TiferetTest do
  use ExUnit.Case

  import Tiferet

  alias Tiferet.InvalidDependencyError

  defmodule Encoder do
    @callback encode!(term) :: binary
  end

  defmodule MapEncoder do
    @behaviour Encoder

    def encode!(%{__struct__: _} = struct) do
      Map.drop(struct, [:__struct__])
    end
  end

  defpmodule Person, encoder: Encoder, formatter: 1 do
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

  test "function dependencies are validated by arity" do
    defpmodule Validation.FunctionDependency, dep: 2 do
      def call(a, b) do
        dep().(a, b)
      end
    end

    assert_raise(InvalidDependencyError, fn ->
      definst(Validation.FunctionDependency, Validation.FunctionDependency.TooFew,
        dep: fn a -> a end
      )
    end)

    assert_raise(InvalidDependencyError, fn ->
      definst(Validation.FunctionDependency, Validation.FunctionDependency.TooMany,
        dep: fn a, b, c -> a * b * c end
      )
    end)

    definst(Validation.FunctionDependency, Validation.FunctionDependency.Valid,
      dep: fn a, b -> a * b end
    )

    assert 6 == Validation.FunctionDependency.Valid.call(2, 3)
  end

  test "module dependencies are validated" do
    defmodule Validation.ModuleDependency.Behaviour do
      @callback call(term) :: term
    end

    defmodule Validation.ModuleDependency.Behaviour.Impl do
      def call(a), do: a
    end

    defpmodule Validation.ModuleDependency, dep: Validation.ModuleDependency.Behaviour do
      def call(a) do
        dep().call(a)
      end
    end

    assert_raise(InvalidDependencyError, fn ->
      definst(Validation.ModuleDependency, Validation.ModuleDependency.WrongType,
        dep: fn a -> a end
      )
    end)

    definst(Validation.ModuleDependency, Validation.ModuleDependency.Valid,
      dep: Validation.ModuleDependency.Behaviour.Impl
    )

    assert 5 == Validation.ModuleDependency.Valid.call(5)
  end
end
