defmodule Tiferet do
  defmacro defpmodule(name, dependencies, do: body) do
    quote do
      defmodule unquote(name) do
        def __dependencies__ do
          unquote(dependencies)
        end

        defmacro __using__(_opts) do
          quote bind_quoted: [body: unquote(Macro.escape(body))] do
            body
          end
        end
      end
    end
  end

  defmacro definst(pmodule, name, dependencies) do
    quote do
      validate_dependencies(unquote(dependencies), unquote(pmodule))

      defmodule unquote(name) do
        use unquote(pmodule)

        inject_dependencies(unquote(dependencies), unquote(pmodule))
      end
    end
  end

  def validate_dependencies(dependencies, pmodule) do
    for {k, v} <- dependencies do
      case Keyword.fetch!(pmodule.__dependencies__, k) do
        n when is_function(v, n) ->
          :ok
        mod when is_atom(mod) and is_atom(v) ->
          :ok
      end
    end
  end

  defmacro inject_dependencies(dependencies, pmodule) do
    dependency_reference =
      quote unquote: false do
        unquote(dependency)
      end

    quote do
      for {dependency, _value} <- unquote(pmodule).__dependencies__ do
        def unquote(dependency_reference)() do
          Keyword.fetch!(unquote(dependencies), unquote(dependency_reference))
        end
      end
    end
  end
end
