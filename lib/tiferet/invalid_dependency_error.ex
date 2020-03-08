defmodule Tiferet.InvalidDependencyError do
  alias __MODULE__

  @type t :: %InvalidDependencyError{
          message: String.t(),
          pmodule: module(),
          instance: module(),
          dependency: atom()
        }

  defexception message: "Invalid dependency passed",
               pmodule: nil,
               instance: nil,
               dependency: nil

  @spec new(module(), module(), atom()) :: t()
  def new(pmodule, instance, dependency_name) do
    %InvalidDependencyError{
      pmodule: pmodule,
      instance: instance,
      dependency: dependency_name,
      message: "#{instance} does not conform to the definition of #{pmodule}.#{dependency_name}"
    }
  end
end
