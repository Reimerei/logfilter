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
        meta_string = Enum.reduce(metadata, "", fn({key, value}, acc) -> acc <> " " <> to_string(key) <> "=" <> to_string(value) end)
        msg_with_meta = unquote(msg) <> " |" <> meta_string
        Logger.log(:debug, msg_with_meta)
      end
    end
  end

  defp form_fa({name, arity}) do
    Atom.to_string(name) <> "/" <> Integer.to_string(arity)
  end

  defp form_fa(nil), do: nil

  def set_filters(caller, metadata) do
    set_filters([{caller, metadata}])
  end

  def set_filters(filters \\ []) do 

    create_filter_def = fn({caller, metadata}) -> "def filter(" <> inspect(caller) <> "," <> inspect(metadata) <> "), do: true" end
    
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