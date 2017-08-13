defmodule Connex.RedisTest do
  use ExUnit.Case

  test "run" do
    child_specs = Connex.Redis.child_specs()
    {:ok, pid} = Supervisor.start_link(child_specs, strategy: :one_for_one)

    assert "OK" == Connex.Redis.run(:pool1, fn client -> Redix.command!(client, ["SET", "key", "value1"]) end)
    assert "OK" == Connex.Redis.run(:pool2, fn client -> Redix.command!(client, ["SET", "key", "value2"]) end)
    assert "OK" == Connex.Redis.run(:pool3, fn client -> Redix.command!(client, ["SET", "key", "value3"]) end)
    assert "value1" == Connex.Redis.run(:pool1, fn client -> Redix.command!(client, ["GET", "key"]) end)
    assert "value2" == Connex.Redis.run(:pool2, fn client -> Redix.command!(client, ["GET", "key"]) end)
    assert "value3" == Connex.Redis.run(:pool3, fn client -> Redix.command!(client, ["GET", "key"]) end)

    Supervisor.stop(pid)
  end

  test "shard" do
    child_specs = Connex.Redis.child_specs()
    {:ok, pid} = Supervisor.start_link(child_specs, strategy: :one_for_one)

    assert "OK" == Connex.Redis.shard(:shard1, "test1", fn client -> Redix.command!(client, ["SET", "key", "value1"]) end)
    assert "OK" == Connex.Redis.shard(:shard1, "test2", fn client -> Redix.command!(client, ["SET", "key", "value2"]) end)
    assert "OK" == Connex.Redis.shard(:shard1, "test8", fn client -> Redix.command!(client, ["SET", "key", "value3"]) end)

    assert "value1" == Connex.Redis.shard(:shard1, "test1", fn client -> Redix.command!(client, ["GET", "key"]) end)
    assert "value2" == Connex.Redis.shard(:shard1, "test2", fn client -> Redix.command!(client, ["GET", "key"]) end)
    assert "value3" == Connex.Redis.shard(:shard1, "test8", fn client -> Redix.command!(client, ["GET", "key"]) end)

    assert "OK" == Connex.Redis.shard(:shard2, "test1", fn client -> Redix.command!(client, ["SET", "key", "value3"]) end)
    assert "OK" == Connex.Redis.shard(:shard2, "test5", fn client -> Redix.command!(client, ["SET", "key", "value2"]) end)

    assert "value3" == Connex.Redis.shard(:shard2, "test1", fn client -> Redix.command!(client, ["GET", "key"]) end)
    assert "value2" == Connex.Redis.shard(:shard2, "test5", fn client -> Redix.command!(client, ["GET", "key"]) end)

    Supervisor.stop(pid)
  end

  test "apis" do
    child_specs = Connex.Redis.child_specs()
    {:ok, pid} = Supervisor.start_link(child_specs, strategy: :one_for_one)

    assert "OK" == Connex.Redis.flushdb!(:pool1)

    assert nil == Connex.Redis.get!(:pool1, "key")
    assert {:ok, nil} == Connex.Redis.get(:pool1, "key")

    assert "OK" == Connex.Redis.set!(:pool1, :key, :value, [:ex, 10])

    assert nil == Connex.Redis.set!(:pool1, :key, :value_nx, [:nx])
    assert "value" == Connex.Redis.get!(:pool1, "key")

    assert "OK" == Connex.Redis.set!(:pool1, "key", "value1")
    assert "OK" == Connex.Redis.set!(:pool2, "key", "value2")
    assert "OK" == Connex.Redis.set!(:pool3, "key", "value3")
    assert "value1" == Connex.Redis.get!(:pool1, "key")
    assert "value2" == Connex.Redis.get!(:pool2, "key")
    assert "value3" == Connex.Redis.get!(:pool3, "key")

    assert {:ok, "value3"} == Connex.Redis.get(:pool3, "key")

    # shards
    assert "OK" == Connex.Redis.shard_set!(:shard1, "test1", "key", "value1")
    assert "OK" == Connex.Redis.shard_set!(:shard1, "test2", "key", "value2")
    assert "OK" == Connex.Redis.shard_set!(:shard1, "test8", "key", "value3")

    assert "value1" == Connex.Redis.shard_get!(:shard1, "test1", "key")
    assert "value2" == Connex.Redis.shard_get!(:shard1, "test2", "key")
    assert "value3" == Connex.Redis.shard_get!(:shard1, "test8", "key")

    assert "OK" == Connex.Redis.shard_set!(:shard2, "test1", "key", "value3")
    assert "OK" == Connex.Redis.shard_set!(:shard2, "test5", "key", "value2")

    assert "value3" == Connex.Redis.shard_get!(:shard2, "test1", "key")
    assert "value2" == Connex.Redis.shard_get!(:shard2, "test5", "key")

    Supervisor.stop(pid)
  end
end
