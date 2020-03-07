defmodule Tiferet do
  defmacro defpmodule(name, dependencies, do: body) do
    quote do
      defmodule unquote(name) do
        @dependencies unquote(dependencies)

        def __dependencies__ do
          @dependencies
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
    dependency_reference =
      quote unquote: false do
        unquote(dependency)
      end

    quote do
      for {k, v} <- unquote(dependencies) do
        case Keyword.fetch!(unquote(pmodule).__dependencies__, k) do
          n when is_function(v, n) ->
            :ok
          mod when is_atom(mod) and is_atom(v) ->
            :ok
        end
      end

      defmodule unquote(name) do
        use unquote(pmodule)

        for {dependency, _value} <- unquote(pmodule).__dependencies__ do
          def unquote(dependency_reference)() do
            Keyword.fetch!(unquote(dependencies), unquote(dependency_reference))
          end
        end
      end
    end
  end
end
