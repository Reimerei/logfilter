defmodule LogfilterTest do
  use ExUnit.Case
  require Log

  defmacro wait_for(msg, timeout \\ 1000) do
    quote do
      receive do
        unquote(msg) ->
          true
        after
          unquote(timeout) ->
            false
      end
    end
  end

  setup do
    Logger.configure(level: :debug)
  end

  test "message as fun is not evaluated when filter is off" do
      log_fun1 = fn() ->
        send(self(), :log1)
        "ok"
      end
      Log.set_filters(%{never: :match}, %{})
      Log.debug(log_fun1)
      assert false == wait_for(:log1, 0)

      # "message as fun is evaluated when filter is on" do
      log_fun1 = fn() ->
        send(self(), :log2)
        "ok"
      end
      Log.set_filters(%{}, %{})
      Log.debug(log_fun1)
      assert true == wait_for(:log2)

      # "message as fun is not evaluated when log level is not :debug" do
      log_fun1 = fn() ->
        send(self(), :log2)
        "ok"
      end
      Log.set_filters(%{}, %{})
      Logger.configure(level: :warn)
      Log.debug(log_fun1)
      assert false == wait_for(:log2, 0)
  end

end
