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
end
