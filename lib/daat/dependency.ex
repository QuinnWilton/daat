defmodule Daat.Dependency do
  alias Daat.InvalidDependencyError

  def validate(dependencies, pmodule, instance) do
    for {dep_name, dep_value} <- dependencies do
      decl = Keyword.fetch!(pmodule.__dependencies__, dep_name)

      valid =
        cond do
          is_integer(decl) ->
            is_function(dep_value, decl)

          is_atom(decl) ->
            Code.ensure_loaded(decl)

            cond do
              function_exported?(decl, :behaviour_info, 1) and is_atom(dep_value) ->
                Code.ensure_loaded(dep_value)

                Enum.all?(decl.behaviour_info(:callbacks), fn {fun, arity} ->
                  function_exported?(dep_value, fun, arity)
                end)

              :else ->
                is_atom(dep_value)
            end
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
