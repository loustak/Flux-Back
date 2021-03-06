defmodule Flux.Discussion do
  use Flux.Web, :model

  schema "discussions" do
    belongs_to :communities, Flux.Community, foreign_key: :community_id
    field :name, :string, null: false
    many_to_many :users, Flux.User, join_through: "user_discussions"
    has_many :messages, Flux.Message

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:community_id, :name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 24)
  end
end
