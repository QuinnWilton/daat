defmodule Daat.Examples.QueueTest do
  use ExUnit.Case
  use ExUnitProperties

  import Daat

  @moduledoc """
  This is a really silly example, but hear me out.

  Here I define a behaviour for a Stack data structure, and then I define
  a parameterized Queue module that gets defined in terms of a Stack. This
  allows me to instantiate Queues using different underlying Stack
  implementations.

  There's a few reasons you might want to do this:
  1) Oftentimes, efficient purely functional datastructures are defined
     using a technique known as data-structural bootstrapping, in which
     a simple (but inefficient) data structure is used to construct
     an efficient one. For more information on this, see
     [Purely Functional Data Structures](https://www.cs.cmu.edu/~rwh/theses/okasaki.pdf)

  2) Sometimes, for efficiency reasons, we need to implement a complicated,
     but hard to verify data structure. If such a data structure is difficult
     to test, it may be worthwhile to also implement a simpler, inefficient
     data structure, that can be used as an oracle for testing the complicated
     structure. By then depending on a parameterized version of the data
     structure, we can avoid duplicating that code for both variants, and
     needing to maintain and test both copies independently.

  It's a contrived example, but this test acts as a demonstration of both
  techniques.

  First, we demonstrate how an efficient queue can be implemented in terms of
  two (abstract) stacks.

  Then we demonstrate how property testing can be used to verify that a simple
  implementation of such a queue (using a list) is equivalent to a more
  complicated implementation (using Church encodings).

  In practice, this example doesn't make a ton of sense, but it was fun to write,
  and I think it shows off the power of using one implementation as an oracle
  to test another. I don't know about you, but I can't tell that ChurchStack
  is correct just from looking at it.
  """

  defmodule Stack do
    @callback empty() :: term()
    @callback empty?(term()) :: boolean()
    @callback push(term(), term()) :: term()
    @callback pop(term()) :: {:ok, term()} | :empty
    @callback top(term()) :: {:ok, term()} | :empty
  end

  defmodule ListStack do
    @behaviour Stack

    def empty(), do: []

    def empty?([]), do: true
    def empty?(_), do: false

    def push(s, x), do: [x | s]

    def pop([]), do: :empty
    def pop([_ | xs]), do: {:ok, xs}

    def top([]), do: :empty
    def top([x | _]), do: {:ok, x}
  end

  defmodule ChurchStack do
    @behaviour Stack

    def empty(), do: fn n, _ -> n.() end
    def empty?(l), do: l.(fn -> true end, fn _, _ -> false end)
    def push(l, x), do: fn _, p -> p.(x, l) end
    def pop(l), do: l.(fn -> :empty end, fn _, b -> {:ok, b} end)
    def top(l), do: l.(fn -> :empty end, fn a, _ -> {:ok, a} end)
  end

  defpmodule Queue, stack: Stack do
    @type t() :: {term(), term()}

    def empty(), do: {stack().empty(), stack().empty()}

    def empty?({s1, s2}) do
      stack().empty?(s1) and stack().empty?(s2)
    end

    def enqueue({s1, s2}, x) do
      {stack().push(s1, x), s2}
    end

    def dequeue({s1, s2} = q) do
      cond do
        empty?(q) ->
          :empty

        stack().empty?(s2) ->
          dequeue({stack().empty(), reverse(s1)})

        :else ->
          {:ok, top} = stack().top(s2)
          {:ok, tail} = stack().pop(s2)

          {top, {s1, tail}}
      end
    end

    defp reverse(s) do
      loop(s, stack().empty())
    end

    defp loop(old, new) do
      if stack().empty?(old) do
        new
      else
        {:ok, top} = stack().top(old)
        {:ok, tail} = stack().pop(old)

        loop(tail, stack().push(new, top))
      end
    end
  end

  definst(Queue, ListQueue, stack: ListStack)
  definst(Queue, ChurchQueue, stack: ChurchStack)

  test "ListQueue behaves as expected" do
    q = ListQueue.empty()

    assert ListQueue.empty?(q)
    assert q = ListQueue.enqueue(q, 5)
    assert q = ListQueue.enqueue(q, 3)
    assert {5, q} = ListQueue.dequeue(q)
    assert {3, q} = ListQueue.dequeue(q)
    assert :empty = ListQueue.dequeue(q)
  end

  property "ListQueue and ChurchQueue behave identically" do
    command =
      one_of([
        constant(:dequeue),
        tuple({constant(:enqueue), term()})
      ])

    check all(commands <- list_of(command, min_length: 5)) do
      q1 = ListQueue.empty()
      q2 = ChurchQueue.empty()

      Enum.reduce(commands, {q1, q2}, fn command, {q1, q2} ->
        case command do
          {:enqueue, x} ->
            q1 = ListQueue.enqueue(q1, x)
            q2 = ChurchQueue.enqueue(q2, x)

            assert ListQueue.empty?(q1) == ChurchQueue.empty?(q2)

            {q1, q2}

          :dequeue ->
            case {ListQueue.dequeue(q1), ChurchQueue.dequeue(q2)} do
              {:empty, :empty} ->
                assert ListQueue.empty?(q1)
                assert ChurchQueue.empty?(q2)

                {q1, q2}

              {{x1, q1}, {x2, q2}} ->
                assert x1 == x2
                assert ListQueue.empty?(q1) == ChurchQueue.empty?(q2)

                {q1, q2}
            end
        end
      end)
    end
  end
end
