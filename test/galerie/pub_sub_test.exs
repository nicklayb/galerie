defmodule Galerie.PubSubTest do
  use Galerie.BaseCase

  alias Galerie.PubSub

  @topics %{
    Galerie.User => "users",
    Galerie.Project => "projects"
  }

  describe "topic/1" do
    for {module, topic} <- @topics do
      test "creates topic for #{inspect(topic)}" do
        expected_topic = unquote(topic)
        assert expected_topic == PubSub.topic(unquote(module))
      end

      test "creates identifier topic for #{inspect(topic)}" do
        expected_topic = "#{unquote(topic)}:10"
        assert expected_topic == PubSub.topic({unquote(module), 10})
      end

      test "creates sub topic for #{inspect(topic)}" do
        expected_topic = "#{unquote(topic)}:10:children"
        assert expected_topic == PubSub.topic({unquote(module), 10, :children})
      end
    end

    test "creates session topic" do
      session_id = Ecto.UUID.generate()
      assert "live_session:#{session_id}" == PubSub.topic({:live_session, session_id})
    end

    test "raises for unsupported topic" do
      assert_raise(FunctionClauseError, fn -> PubSub.topic(Bicycle) end)
    end
  end

  describe "broadcast/2 | subscribe/1" do
    test "broadcasts a wrapped message" do
      string_topic = PubSub.topic(Galerie.User)
      PubSub.subscribe(Galerie.User)
      PubSub.broadcast(Galerie.User, :hello)

      assert_receive(%PubSub.Message{
        message: :hello,
        params: nil,
        from: :none,
        topic: ^string_topic
      })
    end

    test "broadcasts to multiple topic wrapped message" do
      user_topic = PubSub.topic(Galerie.User)
      project_topic = PubSub.topic(Galerie.Project)
      topics = [Galerie.User, Galerie.Project]
      PubSub.subscribe(topics)
      PubSub.broadcast(topics, :hello)

      assert_receive(%PubSub.Message{
        message: :hello,
        params: nil,
        from: :none,
        topic: ^user_topic
      })

      assert_receive(%PubSub.Message{
        message: :hello,
        params: nil,
        from: :none,
        topic: ^project_topic
      })
    end

    test "broadcasts to string topics" do
      PubSub.subscribe("topic")
      PubSub.broadcast("topic", :hello)
      assert_receive(%PubSub.Message{message: :hello, params: nil, from: :none, topic: "topic"})
    end
  end
end
