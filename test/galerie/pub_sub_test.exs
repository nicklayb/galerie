defmodule Galerie.PubSubTest do
  use Galerie.BaseCase

  alias Galerie.PubSub

  describe "topic/1" do
    test "creates session topic" do
      session_id = Ecto.UUID.generate()
      assert "live_session:#{session_id}" == PubSub.topic({:live_session, session_id})
    end

    test "creates topic from schema" do
      id = Ecto.UUID.generate()
      assert "albums:#{id}" == PubSub.topic(%Galerie.Albums.Album{id: id})
    end
  end

  describe "broadcast/2 | subscribe/1" do
    test "broadcasts a wrapped message" do
      string_topic = PubSub.topic(Galerie.Accounts.User)
      PubSub.subscribe(Galerie.Accounts.User)
      PubSub.broadcast(Galerie.Accounts.User, :hello)

      assert_receive(%PubSub.Message{
        message: :hello,
        params: nil,
        from: :none,
        topic: ^string_topic
      })
    end

    test "broadcasts to multiple topic wrapped message" do
      user_topic = PubSub.topic(Galerie.Accounts.User)
      picture_topic = PubSub.topic(Galerie.Pictures.Picture)
      topics = [Galerie.Accounts.User, Galerie.Pictures.Picture]
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
        topic: ^picture_topic
      })
    end

    test "broadcasts to string topics" do
      PubSub.subscribe("topic")
      PubSub.broadcast("topic", :hello)
      assert_receive(%PubSub.Message{message: :hello, params: nil, from: :none, topic: "topic"})
    end
  end
end
