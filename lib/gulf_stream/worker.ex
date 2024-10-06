defmodule GulfStream.Worker do
  use GenServer

  require Logger

  @default_delay 15

  def start_link(worker_id, samples),
    do: GenServer.start_link(__MODULE__, [worker_id, samples])

  @impl true
  def init([worker_id, samples]),
    do: {:ok, {:idl, worker_id, samples, @default_delay}}

  def run(pid, target_bytes),
    do: GenServer.cast(pid, {:run, self(), target_bytes, @default_delay})

  def run_with_delay(pid, target_bytes, delay),
    do: GenServer.cast(pid, {:run, self(), target_bytes, delay})

  def idl(pid),
    do: GenServer.cast(pid, :idl)

  def tick(pid, caller_pid, target_bytes, delay),
    do: Process.send_after(pid, {:tick, caller_pid, target_bytes, delay}, delay)

  @impl true
  def handle_cast({:run, owner_pid, target_bytes, _delay}, state) do
    case state do
      {:idl, worker_id, samples, delay} ->
        Logger.info("Worker #{worker_id} received run command in idle state")
        tick(self(), owner_pid, target_bytes, delay)
        {:noreply, {:running, worker_id, samples, delay}}

      {state, worker_id, _samples, _delay} ->
        Logger.info("Worker #{worker_id} received run command in #{state} state")
        {:noreply, state}
    end
  end

  def handle_cast(:idl, {_, worker_id, samples, target_bytes, delay}) do
    {:noreply, {:idl, worker_id, samples, target_bytes, delay}}
  end

  @impl true
  def handle_info({:tick, caller_pid, target_bytes, _delay}, state) do
    case state do
      {:idl, _worker_id, _samples, _} ->
        {:noreply, state}

      {:running, worker_id, samples, delay} ->
        acc =
          samples
          |> Enum.reduce_while("", fn sample, acc ->
            time = DateTime.utc_now() |> DateTime.to_iso8601()
            str_acc = acc <> String.replace(sample, "$DATE_TIME", time) <> "\n"
            bytes = byte_size(str_acc)

            if bytes <= target_bytes do
              {:cont, str_acc}
            else
              {:halt, acc}
            end
          end)
        write(acc, worker_id)
        send(caller_pid, {:done, worker_id, byte_size(acc), DateTime.utc_now()})
        tick(self(), caller_pid, target_bytes, delay)
        {:noreply, state}
    end
  end

  defp write(sample, worker_id) do
    #File.write!("output_#{worker_id}.txt", sample)
    IO.puts(sample)
  end
end
