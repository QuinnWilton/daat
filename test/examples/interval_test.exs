defmodule Daat.Examples.IntervalTest do
  use ExUnit.Case

  import Daat

  @moduledoc """
  In this example, we define a parameterized module, Interval, which provides
  a generic interface for constructing and working with intervals of arbitrary
  elements.

  We impose that an instance of Interval includes a module, `comparable`, which
  defines a `compare/2` function. Note that this is the same interface used by
  Elixir's built-in sorting functions, as of Elixir 1.10. As a result, we are
  able to easily instantiate the module using the `Date` or `DateTime` modules,
  in order to define a module meant for working with intervals or `Date` or
  `DateTime` elements respectively.

  I don't do it in this example, but if we were to define property tests for the
  abstract Interval pmodule, we would then be able to easily test that instances
  of the Interval pmodule pass those same tests.
  """

  defmodule Comparable do
    @callback compare(term, term) :: :lt | :eq | :gt
  end

  defmodule ComparableNumber do
    def compare(a, b) do
      cond do
        a < b -> :lt
        a == b -> :eq
        a > b -> :gt
      end
    end
  end

  defpmodule Interval, comparable: Comparable do
    @type t ::
            {term, term}
            | :empty

    def create(low, high) do
      if comparable().compare(low, high) == :gt do
        :empty
      else
        {low, high}
      end
    end

    def empty?(:empty), do: true
    def empty?(_), do: false

    def contains?(:empty, _), do: false

    def contains?({low, high}, item) do
      compare_low = comparable().compare(item, low)
      compare_high = comparable().compare(item, high)

      case {compare_low, compare_high} do
        {:eq, _} -> true
        {_, :eq} -> true
        {:gt, :lt} -> true
        _ -> false
      end
    end

    def intersect(t1, t2) do
      min = fn x, y ->
        case comparable().compare(x, y) do
          :lt -> x
          _ -> y
        end
      end

      max = fn x, y ->
        case comparable().compare(x, y) do
          :gt -> x
          _ -> y
        end
      end

      case {t1, t2} do
        {:empty, _} ->
          :empty

        {_, :empty} ->
          :empty

        {{l1, h1}, {l2, h2}} ->
          create(max.(l1, l2), min.(h1, h2))
      end
    end
  end

  definst(Interval, DateInterval, comparable: Date)
  definst(Interval, DateTimeInterval, comparable: DateTime)
  definst(Interval, NumberInterval, comparable: ComparableNumber)

  test "contains?/2 works with Dates" do
    today = Date.utc_today()

    yesterday = Date.add(today, -1)
    tomorrow = Date.add(today, 1)

    ereyesterday = Date.add(today, -2)
    overmorrow = Date.add(today, 2)

    interval = DateInterval.create(yesterday, tomorrow)

    assert true == DateInterval.contains?(interval, yesterday)
    assert true == DateInterval.contains?(interval, today)
    assert true == DateInterval.contains?(interval, tomorrow)
    assert false == DateInterval.contains?(interval, ereyesterday)
    assert false == DateInterval.contains?(interval, overmorrow)
  end

  test "contains?/2 works with DateTimes" do
    datetime1 = DateTime.utc_now()
    datetime2 = DateTime.add(datetime1, 1)
    datetime3 = DateTime.add(datetime1, 2)
    datetime4 = DateTime.add(datetime1, 3)
    datetime5 = DateTime.add(datetime1, 4)

    interval = DateTimeInterval.create(datetime2, datetime4)

    assert true == DateTimeInterval.contains?(interval, datetime2)
    assert true == DateTimeInterval.contains?(interval, datetime3)
    assert true == DateTimeInterval.contains?(interval, datetime4)
    assert false == DateTimeInterval.contains?(interval, datetime1)
    assert false == DateTimeInterval.contains?(interval, datetime5)
  end

  test "contains?/2 works with numbers" do
    interval = NumberInterval.create(0, 10)

    assert true == NumberInterval.contains?(interval, 0)
    assert true == NumberInterval.contains?(interval, 5)
    assert true == NumberInterval.contains?(interval, 10)
    assert false == NumberInterval.contains?(interval, -1)
    assert false == NumberInterval.contains?(interval, 11)
  end

  test "intersect/2" do
    interval1 = NumberInterval.create(0, 10)
    interval2 = NumberInterval.create(3, 15)

    assert {3, 10} == NumberInterval.intersect(interval1, interval2)
  end
end
