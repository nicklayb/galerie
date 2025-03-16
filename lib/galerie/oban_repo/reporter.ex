defmodule Galerie.ObanRepo.Reporter do
  def attach do
    :telemetry.attach_many(
      "oban-logger",
      [
        [:oban, :job, :start],
        [:oban, :job, :stop],
        [:oban, :job, :exception],
        [:oban, :engine, :insert_job, :stop]
      ],
      &__MODULE__.handle_event/4,
      []
    )
  end

  def handle_event(telemetry_event, _, meta, _) do
    with {topic, event} <- pubsub_event_from_telemetry_event(telemetry_event) do
      Galerie.PubSub.broadcast(topic, {event, meta})
    end
  end

  defp pubsub_event_from_telemetry_event([:oban, :job, :start]), do: {"oban:job", :job_start}
  defp pubsub_event_from_telemetry_event([:oban, :job, :stop]), do: {"oban:job", :job_stop}

  defp pubsub_event_from_telemetry_event([:oban, :job, :exception]),
    do: {"oban:job", :job_exception}

  defp pubsub_event_from_telemetry_event([:oban, :engine, :insert_job, :stop]),
    do: {"oban:job", :job_insert}

  defp pubsub_event_from_telemetry_event(_), do: nil
end
