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
     {:basehangul, "~> 0.1.0"},
      ... ]
end
```

This implementation supports encoding/decoding through any I/O devices.

```elixir
% iex -S mix

iex(1)> {:ok, sio} = StringIO.open "Hello, world!"
{:ok, #PID<0.180.0>}
iex(2)> BaseHangul.encode sio    # default output device is `Process.group_leader()`.
낏뗐맸굉깖둠덱뮴닥땡결흐:ok
iex(3)> {:ok, sio} = StringIO.open "낏뗐맸굉깖둠덱뮴닥땡결흐"
{:ok, #PID<0.184.0>}
iex(4)> BaseHangul.decode sio, :stdio
Hello, world!:ok
```

And it takes strings(binaries), too. In this case, those functions return a result string(binary).

```elixir
iex(5)> encoded = BaseHangul.encode "Hello, world!"
"낏뗐맸굉깖둠덱뮴닥땡결흐"
iex(6)> decoded = BaseHangul.decode encoded
"Hello, world!"
iex(7)> [encoded, decoded]
["낏뗐맸굉깖둠덱뮴닥땡결흐", "Hello, world!"]
```

Have fun!

## License

Copyright &copy; Dalgona. <dalgona@hontou.moe>

You can do whatever you wanna do as long as you **do not** sell the source code or compiled binaries to anyone else.

This software is provided **"AS IS"**. I **do not** guarantee that this software will work correctly forever and I **am not** responsible for any loss of data caused by this software.

## Changelog

### 0.1.0 (22 March 2016)

Initial development release. `basehangul` is now available on [Hex](https://hex.pm/packages/basehangul/0.1.0).

### `nil` (22 March 2016)

Initial commit.
