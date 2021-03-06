defmodule Mix.Tasks.Sweetroll2.Export do
  use Mix.Task

  @shortdoc "Export entries from the Mnesia DB as JSON Lines to stdout"

  @impl Mix.Task
  @doc false
  def run(_raw_args) do
    :ok = Memento.start()
    :ok = :mnesia.wait_for_tables([Sweetroll2.Post], 1000)

    posts = Memento.transaction!(fn -> Memento.Query.all(Sweetroll2.Post) end)

    for post <- posts do
      post |> Sweetroll2.Post.to_map() |> Jason.encode!() |> IO.puts()
    end
  end
end
