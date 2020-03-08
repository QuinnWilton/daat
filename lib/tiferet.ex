defmodule Tiferet do
  alias Tiferet.InvalidDependencyError

  defmacro defpmodule(name, dependencies, do: body) do
    quote do
      defmodule unquote(name) do
        def __dependencies__() do
          unquote(dependencies)
        end

        defmacro __using__(_opts) do
          unquote(Macro.escape(body))
        end
      end
    end
  end

  defmacro definst(pmodule, instance, dependencies) do
    quote do
      validate_dependencies(
        unquote(dependencies),
        unquote(pmodule),
        unquote(instance)
      )

      defmodule unquote(instance) do
        use unquote(pmodule)

        inject_dependencies(unquote(dependencies), unquote(pmodule))
      end
    end
  end

  def validate_dependencies(dependencies, pmodule, instance) do
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

  defmacro inject_dependencies(dependencies, pmodule) do
    dependency_reference =
      quote unquote: false do
        unquote(dependency)
      end

    quote do
      for {dependency, _value} <- unquote(pmodule).__dependencies__() do
        def unquote(dependency_reference)() do
          Keyword.fetch!(unquote(dependencies), unquote(dependency_reference))
        end
      end
    end
  end
end
