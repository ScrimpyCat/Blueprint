# Blueprint
Visualise various aspects of your Elixir application

Usage
-----

This library can be used as an API in your own app, or as a mix task, or as an escript.

For escript simply build it using:

```bash
MIX_ENV=prod mix escript.build
mix escript.install blueprint
```

Or download a build from the releases.

Installation
------------
```elixir
defp deps do
    [{ :blueprint, "~> 0.3.2" }]
end
```
