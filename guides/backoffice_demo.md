# Backoffice Demo

A simple demo of how to use Mandarin to implement a simple backoffice area
for your Phoenix web application.

## Introduction

Mandarin is a set of generators inspired by the Phoenix CRUD generators
which can help in writing admin interface for you web application.
The generators are inspired by the default `phoenix.gen.*` generators,
and follow almost exactly the same structures.

These generators generate *normal* phoenix conrollers, views and templates,
which you can customize to your liking.
The generated code may be quite verbose, but because it's *normal elixir code*,
it's also trivial to customize to your liking (it would be pretty impossible
to customize if it were based on metaprogramming).

This approach is different from the one found in  admin frameworks from other languages, which use class reflection or metaprogramming, such as some Python frameworks
([Django](https://www.djangoproject.com/),
[Flask-Admin](https://flask-admin.readthedocs.io/en/latest/),
[Flask-AppBuilder](https://flask-appbuilder.readthedocs.io/en/latest/))
and Ruby frameworks
([ActiveAdmin](https://activeadmin.info/)).

This application we'll develop in this guide is inspired by the small example
in the [Flask-Appbuider docs](https://flask-appbuilder.readthedocs.io/en/latest/relations.html). The main difference is that we'll write ir using the Mandarin generators, while
the AppBuilder version will uses class reflection.

## Application Layout

We'll generate an admin interface that manages 3 different kinds of resources:

  * Employees
  * Departments, where each employee belongs to a single department
  * Functions, where each employee has a single function

This structure will show how Mandarin generators handle one-to-many relations
(a future version will show how they handle many-to-many relations).

## Add the Dependencies

```elixir
# mix.exs

  defp deps do
    [
      # ...
      # Mandarin
      {:mandarin, path: "../mandarin"},
      {:forage, path: "../forage", override: true},
      # Utilities to generate fake data
      {:faker, "~> 0.16", only: :dev}
    ]
  end
```

## "Install" Mandarin Into Your Application

You can have as many admin interfaces in your application as you want.
An admin interface is just a new context with schemas, views, controllers and templates
generated by Mandarin.

You "install" mandarin into your application by giving it a new context name.
Mandarin will then generate everything under that context.

```sh
mix mandarin.install Backoffice
```

## Add the Resources to the Mandarin Context

Mandarin provides generators, which are similar to the default Phoenix generators.
The goal is to build your CRUD interface with the generators, and maybe customize
the interface later if you feel the need to.
Mandarin will generate and application structure which is quite similar to the default
phoenix structure.
The main difference is the use of "vertical slicing" or "feature folders".

You can now generate the pages for our resources with the generators.

### Department

Type the following (and answer *Yes* to the prompts as needed):

```sh
mix mandarin.gen.html Backoffice Department departments \
  name:string description:text --binary-id
```

### Function

```sh
mix mandarin.gen.html Backoffice Function functions name:string --binary-id
```

### Employee

```sh
mix mandarin.gen.html Backoffice Employee employees \
  full_name:string address:string fiscal_number:string \
  department:references:departments function:references:functions \
  begin_date:date end_date:date --binary-id
```

## Testing

Mandarin has generated some tests for your context and controllers.
The tests are pretty basic, but they at least test that the relevant
pages load without errors and invoke the appropriate actions in your Repo.

You can run the automatically generated tests with:

```sh
mix test
```

## Generate Some Fake Data

Alias the context module, which we will use to create our resources:

```elixir
alias MandarinDemo.Backoffice
```

Create some WH40k-inspired departments for our company:

```elixir
department_names = [
  "Inquisition",
  "Oficia Censorum",
  "Ordo Xenos",
  "Ordo Malleus",
  "Sororitas",
  "Adeptus Astartes"
]

# Gather the departments after inserting them into the database
# because we'll be using them later.
departments =
  for name <- department_names do
    {:ok, department} =
      Backoffice.create_department(%{
        name: name,
        # Generate a random description using Faker
        description: Faker.Lorem.paragraph(1..2)
      })

    department
  end
```

A above, create some functions for our employees:

```elixir
function_names = [
  "Janitor",
  "Office Clerk",
  "Lector",
  "Servitor",
  "Adeptus",
  "Maestrus",
  "Techpriest",
  "Cook",
  "Custodes"
]

# Gather the functions after inserting them into the database
# because we'll be using them later.
functions =
  for name <- function_names do
    {:ok, function} = Backoffice.create_function(%{name: name})
    function
  end
```

Add some employees belonging to random functions and departments:

```elixir
_employees =
  for i <- 1..500 do
    {:ok, employee} =

      Backoffice.create_employee(%{
        address: Faker.Address.En.street_address(),
        begin_date: Faker.Date.backward(_days = 365 * 100),
        end_date: Faker.Date.forward(_days = 365 * 100),
        fiscal_number: "SSN-#{Enum.random(0..1000_000_000)}",
        full_name: Faker.Person.En.name(),
        function_id: Enum.random(functions).id,
        department_id: Enum.random(departments).id
      })
  end

```


## Playing with The Application

...