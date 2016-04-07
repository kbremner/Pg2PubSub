defmodule Pg2PubSub do
  @moduledoc """
  Provides methods for subscribing and publishing to named topics.
  """
  require Logger

  @doc """
  Subscribe to a topic

  ## Parameters

    - pid: Process ID for the started PubSub process
    - topic: Name of the topic to subscribe to

  ## Examples

      iex> Pg2PubSub.subscribe("foo")
      {:ok, :registered}

      # subscribing a second time has no effect
      iex> Pg2PubSub.subscribe("foo")
      {:ok, :registered}
      iex> Pg2PubSub.subscribe("foo")
      {:ok, :already_registered}

  """
  @spec subscribe(String.t) :: term
  def subscribe(topic) do
    :ok = Logger.debug "#{inspect self} subscribing to #{topic}..."
    :pg2.create(topic)
    case :pg2.get_members(topic) do
      {:error, error} ->
        :ok = Logger.error "Publisher failed to get members of topic #{topic}: #{error}"
        {:error, error}
      pids ->
        unless self in pids do
          :pg2.join(topic, self)
          :ok = Logger.debug "#{inspect self} subscribed to #{topic}"
          {:ok, :registered}
      else
        :ok = Logger.debug "#{inspect self} already subscribed to #{topic}"
        {:ok, :already_registered}
      end
    end
  end


  @doc """
  Unsubscribe from a topic

  ## Parameters

    - pid: Process ID for the started PubSub process
    - topic: Name of the topic to unsubscribe from

  ## Examples

      iex> Pg2PubSub.subscribe("foo")
      {:ok, :registered}
      iex> Pg2PubSub.unsubscribe("foo")
      :ok

      # unsubscribing when not subscribed will still give an okay result
      iex> Pg2PubSub.unsubscribe("foo")
      :ok

  """
  @spec unsubscribe(String.t) :: term
  def unsubscribe(topic) do
    :ok = Logger.debug "#{inspect self} unsubscribing from #{topic}..."
    case :pg2.leave(topic, self) do
      {:error, {:no_such_group, _topic}} ->
        :ok = Logger.warn "no subscribers for topic #{topic}"
        :ok
      :ok ->
        :ok = Logger.debug "#{inspect self} unsubscribed from #{topic}"
        :ok
    end
  end


  @doc """
  Publish to a topic

  ## Parameters

    - pid: Process ID for the started PubSub process
    - topic: Name of the topic to unsubscribe from

  ## Examples

      iex> Pg2PubSub.subscribe("foo")
      {:ok, :registered}
      iex> Pg2PubSub.publish("foo", "bar")
      :ok
      iex> receive do msg -> msg end
      "bar"

  """
  @spec publish(String.t, any) :: :ok
  def publish(topic, msg) do
    case :pg2.get_members(topic) do
      {:error, err} ->
        {:error, err}
      pids ->
        for pid <- pids, do: send(pid, msg)
        :ok
    end
  end
end
