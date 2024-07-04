defmodule Nectarine.PubSub.MessageTest do
  use Nectarine.BaseCase

  alias Nectarine.PubSub.Message

  describe "new/3" do
    test "creates a new message" do
      pid = self()

      assert %Message{message: :project_created, params: %{id: 1}, topic: "projects", from: ^pid} =
               Message.new({:project_created, %{id: 1}}, pid, "projects")

      assert %Message{message: :project_created, params: nil, topic: "projects", from: ^pid} =
               Message.new(:project_created, pid, "projects")
    end
  end
end
