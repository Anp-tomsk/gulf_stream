defmodule GulfStream.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {GulfStream, Application.get_env(:gulf_stream, :target_bytes, 10_000)}
    ]

    opts = [strategy: :one_for_one, name: GulfStream.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
