defmodule Pg2PubSub do
  @moduledoc """
  Provides methods for subscribing and publishing to named topics.
  """
  use GenServer
  require Logger

  @spec start_link() :: GenServer.on_start
  def start_link() do
    :ok = Logger.debug "Publisher starting..."
    GenServer.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    :ok = Logger.debug "Publisher started (#{inspect self})"
    {:ok, self}
  end

  @spec subscribe(pid, String.t) :: term
  def subscribe(pid, slug) do
    GenServer.call(pid, {:subscribe, slug, self})
  end

  @spec unsubscribe(pid, String.t) :: term
  def unsubscribe(pid, slug) do
    GenServer.call(pid, {:unsubscribe, slug, self})
  end

  @spec publish(pid, String.t, String.t) :: :ok
  def publish(pid, slug, msg) do
    GenServer.cast(pid, {:publish, slug, msg})
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
