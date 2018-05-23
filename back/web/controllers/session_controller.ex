defmodule Flux.SessionController do
  use Flux.Web, :controller

  def create(conn, params) do
    case authenticate(params) do
      {:ok, user} ->
        conn = Flux.Guardian.Plug.sign_in(conn, user, %{claim: "access"}, ttl: {30, :days})
        jwt = Flux.Guardian.Plug.current_token(conn)

        conn
        |> put_status(:created)
        |> render("show.json", user: user, jwt: jwt)
      :error ->
        conn
        |> put_status(:unauthorized)
        |> render("error.json")
    end
  end

  def delete(conn, _params) do

    IO.puts Flux.Guardian.Plug.current_token(conn)
    Flux.Guardian.Plug.sign_out(conn)
    IO.puts Flux.Guardian.Plug.current_token(conn)

    conn
    |> put_status(:ok)
    |> render("delete.json")
  end

  def refresh(conn, _params) do
    token = Flux.Guardian.Plug.current_token(conn)

    case Flux.Guardian.refresh(token, ttl: {30, :days}) do
      {:ok, {_old_token, _old_claims}, {new_token, _new_claims}} ->
        conn
        |> put_status(:ok)
        |> render("token.json", token: new_token)
      {:error, _reason} ->
        conn
        |> put_status(:unauthorized)
        |> render("forbidden.json", error: "not authenticated")
    end
  end

  def read(conn, _params) do
    id = Flux.Guardian.Plug.current_resource(conn)
    user = Repo.get_by(Flux.User, id)

    conn
    |> put_status(:ok)
    |> render(Flux.UserView, "user.json", user: user)
  end

  def unauthenticated(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> render(Flux.SessionView, "forbidden.json", error: "not Authenticated")
  end

  defp authenticate(%{"email" => email, "password" => password}) do
    user = Repo.get_by(Flux.User, email: String.downcase(email))

    case check_password(user, password) do
      true -> {:ok, user}
      _ -> :error
    end
  end

  defp check_password(user, password) do
    case user do
      nil -> Bcrypt.no_user_verify()
      _ -> Bcrypt.verify_pass(password, user.password_hash)
    end
  end
end