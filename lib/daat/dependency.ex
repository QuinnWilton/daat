defmodule Daat.Dependency do
  alias Daat.InvalidDependencyError

  def validate(dependencies, pmodule, instance) do
    for {dep_name, dep_value} <- dependencies do
      declaration = Keyword.fetch!(pmodule.__dependencies__, dep_name)

      valid =
        cond do
          is_integer(declaration) ->
            is_function(dep_value, declaration)

          is_atom(declaration) ->
            is_atom(dep_value)
        end

      if not valid do
        raise InvalidDependencyError.new(pmodule, instance, dep_name)
      end
    end
  end

  defmacro inject(dependencies, pmodule) do
    dependency_reference =
      quote unquote: false do
        unquote(dependency)
      end

    quote do
      for {dependency, _value} <- unquote(pmodule).__dependencies__() do
        defp unquote(dependency_reference)() do
          Keyword.fetch!(unquote(dependencies), unquote(dependency_reference))
        end
      end
    end
  end
end
