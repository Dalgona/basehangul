# BaseHangul

Elixir implementation of BaseHangul, the human-readable binary encoding.

The original PHP implementation can be found [here](https://github.com/koreapyj/basehangul).

## Usage

mix.exs:

```elixir
def application do
    [applications: [ ... , :basehangul]]
end

defp deps do
    [ ... ,
     {:basehangul, "~> 0.9.0"},
      ... ]
end
```

`BaseHangul.encode/1` and `BaseHangul.decode/1` expect a binary
as an argument.

```elixir
iex> BaseHangul.encode("Hello, world!")
"낏뗐맸굉깖둠덱뮴닥땡결흐"
iex> BaseHangul.encode(<<0, 1, 2, 3, 4>>)
"가갚궁링"
```

```elixir
iex> BaseHangul.decode("낏뗐맸굉깖둠덱뮴닥땡결흐")
"Hello, world!"
iex> BaseHangul.decode("가갚궁링")
<<0, 1, 2, 3, 4>>
```

Have fun!

## License

WTFPL

## Changelog

### 0.9.0 (8 February 2019)

* Massive refactoring and overhaul.
* Removed functions taking an IO device.

### 0.2.1 (12 April 2016)

* Now the decoder raises an `ArgumentError` when invalid BaseHangul string is provided as an input.

### 0.2.0 (23 March 2016)

* Added more encoder/decoder wrappers for the convenience.
* Added library documentation.

### 0.1.0 (22 March 2016)

Initial development release. `basehangul` is now available on [Hex](https://hex.pm/packages/basehangul/0.1.0).

### `nil` (22 March 2016)

Initial commit.
