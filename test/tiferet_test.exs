defmodule TiferetTest do
  use ExUnit.Case

  import Tiferet

  defpmodule Person, [:formatter] do
    def speak(message) do
      formatter().(message)
    end
  end

  definst(Person, LoudPerson, formatter: fn s -> String.upcase(s) end)
  definst(Person, QuietPerson, formatter: fn s -> String.downcase(s) end)

  test "parameterized modules are generated" do
    assert "HELLO" == LoudPerson.speak("hello")
    assert "hello" == QuietPerson.speak("HELLO")
  end
end
