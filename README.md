Logfilter
=========

Macros that filter debug messages before they are generated. The filters can be changed during runtime to allow debugging of live systems.
Uses the Elixir Logger.


Usage
=========
Set `require Log` at the beginning of the file.

Create log messages with
```
Log.debug("msg")
Log.info("msg")
Log.warn("msg")
Log.error("msg")
```

By default debug messages will not be shown. To enable them define filters using
```
Log.set_filter(caller, metadata)
```

Debugging pipes
===============

```elixir
[1,2,3]
|> Enum.map(&(&1 * 2))
|> Log.debug("double")
|> Enum.map(&(&1 * 2))
```

this will output the message

```
09:32:25.663 [debug] double: [2, 4, 6] |
```

while leaving the stream intact and returning `[4, 8, 12]`.

Debugging with funs
===============

Sometimes computing the massage might be expensive and you only want to do it
if it is actually shown:

```elixir
generate_message = fn() -> "I did something really complex" end
Log.debug(generate_message)
08:56:04.380 [debug] I did something really complex |
```
