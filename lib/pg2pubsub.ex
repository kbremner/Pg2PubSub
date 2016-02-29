defmodule Pg2PubSub do
  @moduledoc """
  Provides methods for subscribing and publishing to named topics.
  """

  use GenServer
  require Logger

  @doc """
  Starts a PubSub process linked to the calling process

  ## Examples

      iex> {:ok, pid} = Pg2PubSub.start_link
      iex> is_pid(pid)
      true

  """
  @spec start_link() :: GenServer.on_start
  def start_link() do
    :ok = Logger.debug "Publisher starting..."
    GenServer.start_link(__MODULE__, :ok)
  end

  @doc """
  Starts a PubSub process linked to the calling process and with the given name

  ## Examples

      iex> Pg2PubSub.start_link :foo
      {:ok, name: :foo}

      # can use the name when executing an operation
      iex> Pg2PubSub.start_link :foo
      {:ok, name: :foo}
      iex> Pg2PubSub.subscribe(:foo, "foo")
      :ok

  """
  def start_link(name) do
    :ok = Logger.debug "Publisher starting with name..."
    GenServer.start_link(__MODULE__, :ok, name: name)
    {:ok, name: name}
  end

  def init(:ok) do
    :ok = Logger.debug "Publisher started (#{inspect self})"
    {:ok, self}
  end

  @doc """
  Subscribe to a topic

  ## Parameters

    - pid: Process ID for the started PubSub process
    - topic: Name of the topic to subscribe to

  ## Examples

      iex> {:ok, pid} = Pg2PubSub.start_link
      iex> Pg2PubSub.subscribe(pid, "foo")
      :ok

      # subscribing a second time has no effect
      iex> {:ok, pid} = Pg2PubSub.start_link
      iex> Pg2PubSub.subscribe(pid, "foo")
      :ok
      iex> Pg2PubSub.subscribe(pid, "foo")
      {:already_registered, [self]}

  """
  @spec subscribe(pid, String.t) :: term
  def subscribe(pid, topic) do
    GenServer.call(pid, {:subscribe, topic, self})
  end


  @doc """
  Unsubscribe from a topic

  ## Parameters

    - pid: Process ID for the started PubSub process
    - topic: Name of the topic to unsubscribe from

  ## Examples

      iex> {:ok, pid} = Pg2PubSub.start_link
      iex> Pg2PubSub.subscribe(pid, "foo")
      :ok
      iex> Pg2PubSub.unsubscribe(pid, "foo")
      :ok

      # unsubscribing when not subscribed will still give an okay result
      iex> {:ok, pid} = Pg2PubSub.start_link
      iex> Pg2PubSub.unsubscribe(pid, "foo")
      :ok

  """
  @spec unsubscribe(pid, String.t) :: term
  def unsubscribe(pid, topic) do
    GenServer.call(pid, {:unsubscribe, topic, self})
  end


  @doc """
  Publish to a topic

  ## Parameters

    - pid: Process ID for the started PubSub process
    - topic: Name of the topic to unsubscribe from

  ## Examples

      iex> {:ok, pid} = Pg2PubSub.start_link
      iex> Pg2PubSub.subscribe(pid, "foo")
      :ok
      iex> Pg2PubSub.publish(pid, "foo", "bar")
      :ok
      iex> receive do msg -> msg end
      "bar"

  """
  @spec publish(pid, String.t, any) :: :ok
  def publish(pid, topic, msg) do
    GenServer.cast(pid, {:publish, topic, msg})
  end

  @spec handle_call(term, GenServer.from, term) :: {:reply, :ok, term} | {:stop, term, term}
  def handle_call({:subscribe, topic, pid}, from = {from_pid, _ref}, s) do
    :ok = Logger.debug "#{inspect from_pid} subscribing to #{topic}..."
    :pg2.create(topic)
    case :pg2.get_members(topic) do
      {:error, error} ->
        :ok = Logger.error "Publisher failed to get members of topic #{topic}: #{error}"
        {:stop, error, s}
      pids ->
        unless pid in pids do
          :pg2.join(topic, pid)
          :ok = Logger.debug "#{inspect from_pid} subscribed to #{topic}"
          {:reply, :ok, s}
      else
        :ok = Logger.debug "#{inspect from_pid} already subscribed to #{topic}"
        GenServer.reply(from, {:already_registered, pids})
        {:reply, :ok, s}
      end
    end
  end

  def handle_call({:unsubscribe, topic, pid}, from = {from_pid, _ref}, s) do
    :ok = Logger.debug "#{inspect from_pid} unsubscribing from #{topic}..."
    case :pg2.leave(topic, pid) do
      {:error, {:no_such_group, _topic}} ->
        :ok = Logger.warn "no subscribers for topic #{topic}"
        {:reply, :ok, s}
      :ok ->
        :ok = Logger.debug "#{inspect from_pid} unsubscribed from #{topic}"
        {:reply, :ok, s}
    end
  end

  @spec handle_cast(term, term) :: {:noreply, term}
  def handle_cast({:publish, topic, message}, s) do
    case :pg2.get_members(topic) do
      {:error, _} ->
        {:noreply, s}
      pids ->
        for pid <- pids, do: send(pid, message)
        {:noreply, s}
    end
  end
end
