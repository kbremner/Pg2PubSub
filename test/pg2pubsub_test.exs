defmodule Pg2PubSubTest do
  use ExUnit.Case
  doctest Pg2PubSub

  test "can subscribe to a topic" do
    {:ok, pid} = Pg2PubSub.start_link

    res = Pg2PubSub.subscribe("foo", pid)

    assert :ok == res
  end

  test "can publish to a topic" do
    {:ok, pid} = Pg2PubSub.start_link

    res = Pg2PubSub.publish("foo", "bar", pid)

    assert :ok == res
  end

  test "can receive a published message" do
    {:ok, pid} = Pg2PubSub.start_link
    Pg2PubSub.subscribe("foo", pid)

    Pg2PubSub.publish("foo", "bar", pid)

    assert_receive "bar"
  end

  test "won't receive published message if not subscribed" do
    {:ok, pid} = Pg2PubSub.start_link

    Pg2PubSub.publish("foo", "bar", pid)

    refute_receive "bar"
  end

  test "only receive messages for topics that this process is subscribed to" do
    {:ok, pid} = Pg2PubSub.start_link
    Pg2PubSub.subscribe("bar", pid)

    Pg2PubSub.publish("foo", :foo, pid)
    Pg2PubSub.publish("bar", :bar, pid)

    assert_receive :bar
    refute_receive :foo
  end

  test "can unsubscribe from a topic" do
    {:ok, pid} = Pg2PubSub.start_link
    Pg2PubSub.subscribe("foo", pid)

    res = Pg2PubSub.unsubscribe("foo", pid)

    assert :ok == res
  end

  test "unsubscribing from a topic not subscribed is successful" do
    {:ok, pid} = Pg2PubSub.start_link

    res = Pg2PubSub.unsubscribe("foo", pid)

    assert :ok == res
  end

  test "won't receive messages after unsubscribing from a topic" do
    {:ok, pid} = Pg2PubSub.start_link
    Pg2PubSub.subscribe("foo", pid)

    Pg2PubSub.unsubscribe("foo", pid)
    Pg2PubSub.publish("foo", "bar", pid)

    refute_receive "bar"
  end

  test "subscribing a second time has no effect" do
    {:ok, pid} = Pg2PubSub.start_link

    Pg2PubSub.subscribe("foo", pid)
    res = Pg2PubSub.subscribe("foo", pid)

    assert {:already_registered, [self]} == res
  end

  test "only receive message once after attempting to subscribe more than once" do
    {:ok, pid} = Pg2PubSub.start_link

    Pg2PubSub.subscribe("foo", pid)
    Pg2PubSub.subscribe("foo", pid)

    Pg2PubSub.publish("foo", :foo, pid)

    assert_receive :foo
    refute_receive :foo # check only received once
  end
end