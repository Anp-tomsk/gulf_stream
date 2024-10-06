defmodule GulfStream do
  use GenServer

  alias GulfStream.Worker

  require Logger

  def start_link(target_bytes) do
    GenServer.start_link(__MODULE__, target_bytes)
  end

  def init(target_bytes) do
    lines =
      File.read!("samples.txt")
      |> String.split("\n")

    max_workers = Application.get_env(:gulf_stream, :max_workers, 8)
    workers =
      for worker_id <- 1..max_workers do
        {:ok, pid} = Worker.start_link(worker_id, lines)
        Worker.run(pid, target_bytes)
        {worker_id, pid}
      end

    state =
      workers |> Enum.reduce(%{}, fn {worker_id, pid}, acc ->
        Map.put(acc, worker_id, {pid, DateTime.utc_now(), 0})
      end)

    {:ok, state}
  end

  def handle_info({:done, worker_id, bytes, time}, state) do
    {pid, prev_time, prev_writtern} = Map.get(state, worker_id)
    time_diff = DateTime.diff(time, prev_time, :millisecond)
    Logger.info(
      "Worker #{worker_id} done writing #{bytes} bytes in #{time_diff} ms, " <>
      "total byte written: #{prev_writtern + bytes}")
    new_state = Map.put(state, worker_id, {pid, time, prev_writtern + bytes})
    {:noreply, new_state}
  end
end
