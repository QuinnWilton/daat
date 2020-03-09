defmodule Daat do
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
      require Daat.Dependency

      Daat.Dependency.validate(
        unquote(dependencies),
        unquote(pmodule),
        unquote(instance)
      )

      defmodule unquote(instance) do
        use unquote(pmodule)

        Daat.Dependency.inject(unquote(dependencies), unquote(pmodule))
      end
    end
  end
end
