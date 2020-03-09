# Daat
[![hex.pm version](https://img.shields.io/hexpm/v/daat.svg?style=flat)](https://hex.pm/packages/daat) [![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](http://hexdocs.pm/daat/) [![license](https://img.shields.io/github/license/mashape/apistatus.svg?maxAge=2592000)](https://github.com/quinnwilton/daat/blob/master/LICENSE)

> Daʻat is not always depicted in representations of the sefirot; and could be abstractly considered an "empty slot" into which the germ of any other sefirot can be placed.
> — [Wikipedia](https://en.wikipedia.org/wiki/Da%27at)

Daat is an experimental library meant to provide [parameterized modules](https://caml.inria.fr/pub/docs/oreilly-book/html/book-ora132.html) to Elixir.

This library is mostly untested, and should be used at your risk.

## Installation

```elixir
def deps do
  [
    {:daat, "~> 0.1.0"}
  ]
end
```

## Examples

Examples can be found in the [test](https://github.com/quinnwilton/daat/blob/master/test/examples) directory

- [Data Structural Bootstrapping](https://github.com/QuinnWilton/daat/blob/master/test/examples/queue_test.exs)
- [Polymorphic Intervals](https://github.com/QuinnWilton/daat/blob/master/test/examples/interval_test.exs)

## Motivation

Imagine that you have a module named `UserService`, that exposes a function named `follow/2`. When called, the system sends an email to the user being followed. It would be nice if we could extract actually sending the email from this module, so that we aren't coupling ourselves to a specific email client, and so that we can inject mocks into the service for testing purposes.

Typically, Elixir programmers might do this in one of two ways:

- Adding a `send_email` argument to the function, which expects a callback responsible for sending the email
- Fetching the implementation of `send_email` from configuration at runtime

Both of these approaches work, but they have some drawbacks:

- Adding callbacks to all of our function signatures shifts complexity to the caller, and makes for more complicated function signatures
- Storing callbacks in global configuration means losing out on the ability to run multiple instances of the module at once. This might be okay for production environments, but in testing it removes the ability to run all of your tests concurrently
- Because this dependency injection happens at runtime, we are unable to confirm, at compile-time, that the dependencies being passed to a module conform to that modue's requirements

By using parameterized, or higher-order modules, we can instead define a module that specifies an interface, and acts as a generator for modules of that interface. By then passing our dependencies to this generator, we are able to dynamically create new modules that implement our desired behaviour. This approach addresses all three points above.

That being said, this library is highly experimental, and I'm still working out the ideal interface and syntax for supportng this behaviour. If you have ideas, I'd love to hear them!

Here's an example of the above use-case:

```elixir
import Daat

# UserService has one dependency: a function named `send_email/2`
defpmodule UserService, send_email: 2 do
  def follow(user, follower) do
    send_email().(user.email, "You have been followed by: #{follower.name}")
  end
end

definst(UserService, MockUserService, send_email: fn to, body -> :ok end)

user = %{name: "Janice", email: "janice@example.com"}
follower = %{name: "Chris", email: "chris@example.com"}

MockUserService.follow(user, follower)
```

You're also able to specify that a dependency should be a module. My end-goal is to validate that the passed modules conform to a behaviour described by the declaration, but right now I am only validating that you did in fact pass a module.

```elixir
import Daat

defmodule Mailer do
  @callback send_email(to :: String.t(), body :: String.t()) :: :ok
end

defmodule MockMailer do
  @behaviour Mailer

  @impl Mailer
  def send_email(_to, _body) do
    :ok
  end
end

# UserService has one dependency: a function named `send_email/2`
defpmodule UserService, mailer: Mailer do
  def follow(user, follower) do
    mailer().send_email(user.email, "You have been followed by: #{follower.name}")
  end
end

definst(UserService, MockUserService, mailer: MockMailer)

user = %{name: "Janice", email: "janice@example.com"}
follower = %{name: "Chris", email: "chris@example.com"}

MockUserService.follow(user, follower)
```

## Acknowledgements

This library was inspired by [a talk given by @expede](https://codesync.global/speaker/brooklyn-zelenka/#623old-ideas-made-new) at Code BEAM SF 2020