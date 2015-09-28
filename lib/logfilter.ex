defmodule Log do

  defmacro info(msg),      do: quote do: Logger.log(:info, unquote(msg))
  defmacro warn(msg),      do: quote do: Logger.log(:warn, unquote(msg))
  defmacro error(msg),     do: quote do: Logger.log(:error, unquote(msg))

  defmacro metadata(meta) do
    quote do
      old_meta = Process.get(:log_meta) || %{}
      Process.put(:log_meta, Map.merge(old_meta, unquote(meta)))
    end
  end

  defmacro debug(msg) do
    %{module: module, function: fun, line: line} = __CALLER__
    quote do
      caller = %{module: unquote(module), function: unquote(form_fa(fun)), line: unquote(line)}
      metadata = Process.get(:log_meta) || %{}
      if LogFilter.filter(caller, metadata) do
        msg_string    = Log.msg_to_string(unquote(msg))
        meta_string   = Enum.reduce(metadata, "", fn({key, value}, acc) -> acc <> " " <> to_string(key) <> "=" <> to_string(value) end)
        msg_with_meta = msg_string <> " |" <> meta_string
        do_log(msg_with_meta)
      end
    end
  end

  defmacro do_log(msg) do
    # the Logger API has changed in v1.1.0, detect which version we are running
    %{version: elixir_version} = System.build_info()
    case Version.compare(elixir_version, "1.1.0") do
      :lt   -> quote do: Logger.log(:debug, unquote(msg))
      _     -> quote do: Logger.bare_log(:debug, unquote(msg))
    end
  end

  def msg_to_string(msg) when is_function(msg) do
    msg.()
  end

  # we assume msg is a binary of iolist
  def msg_to_string(msg) do
    msg
  end

  defp form_fa({name, arity}) do
    Atom.to_string(name) <> "/" <> Integer.to_string(arity)
  end

  defp form_fa(nil), do: nil

  def debug(data, label) do
    debug(label <> ": #{inspect data}")
    data
  end

  def set_filters(caller, metadata) do
    set_filters([{caller, metadata}])
  end

  def log_default() do
    default_filters = Application.get_env(:logfilter, :default) || []
    set_filters(default_filters)
  end

  def log_none() do
    set_filters([])
  end

  def log_all do
    set_filters([{%{},%{}}])
  end

  def set_filters(filters) do
    create_filter_def = fn({caller, metadata}) -> "def filter(" <> inspect(caller) <> "," <> inspect(metadata) <> "), do:  Logger.level == :debug" end

    filter_defs =
      filters
      |> Enum.map(create_filter_def)
      |> Enum.join("\n")

    module_def =
      "defmodule LogFilter do\n"
      <> filter_defs <> "\n"
      <> "  def filter(_, _), do: false\n"
      <> "end"
    Code.compile_string(module_def)
    :ok
  end
end

defmodule LogFilter do
  def filter(_,_), do: false
end
