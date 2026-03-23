defmodule HivexWorkerTest do
  use ExUnit.Case
  doctest HivexWorker

  test "greets the world" do
    assert HivexWorker.hello() == :world
  end
end
