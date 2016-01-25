defmodule Log do

  defmacro info(msg),      do: quote do: Logger.bare_log(:info, unquote(msg))
  defmacro warn(msg),      do: quote do: Logger.bare_log(:warn, unquote(msg))
  defmacro error(msg),     do: quote do: Logger.bare_log(:error, unquote(msg))

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
        msg_with_meta = 
          if map_size(metadata) == 0 do
            msg_string
          else
            meta_string = Enum.reduce(metadata, "", fn({key, value}, acc) -> "#{acc} #{to_string(key)}=#{to_string(value)}" end)
            msg_string <> " |" <> meta_string
          end
        Logger.bare_log(:debug, msg_with_meta)
      end
    end
  end

  # if the msg is a function execute it, to get the message
  def msg_to_string(msg) when is_function(msg) do
    msg.()
  end

  # we assume msg is a binary or iolist
  def msg_to_string(msg) do
    msg
  end

  defp form_fa({name, arity}) do
    Atom.to_string(name) <> "/" <> Integer.to_string(arity)
  end

  defp form_fa(nil), do: nil

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
  def filter(_,_), do: true
end
