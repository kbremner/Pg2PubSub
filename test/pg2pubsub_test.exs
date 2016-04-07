defmodule Pg2PubSubTest do
  use ExUnit.Case
  doctest Pg2PubSub

  setup do
    :pg2.which_groups
    |> Enum.map fn (x) -> :pg2.delete(x) end
    :ok
  end

  test "won't receive published message if not subscribed" do
    Pg2PubSub.publish("foo", "bar")

    refute_receive "bar"
  end

  test "only receive messages for topics that this process is subscribed to" do
    Pg2PubSub.subscribe("bar")

    Pg2PubSub.publish("foo", :foo)
    Pg2PubSub.publish("bar", :bar)

    assert_receive :bar
    refute_receive :foo
  end

  test "won't receive messages after unsubscribing from a topic" do
    Pg2PubSub.subscribe("foo")

    Pg2PubSub.unsubscribe("foo")
    Pg2PubSub.publish("foo", "bar")

    refute_receive "bar"
  end

  test "only receive message once after attempting to subscribe more than once" do
    Pg2PubSub.subscribe("foo")
    Pg2PubSub.subscribe("foo")

    Pg2PubSub.publish("foo", :foo)

    assert_receive :foo
    refute_receive :foo # check only received once
  end
end