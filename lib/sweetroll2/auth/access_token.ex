defmodule Sweetroll2.Auth.AccessToken do
  @moduledoc """
  A Mnesia table for storing IndieAuth (OAuth) access-tokens.
  """

  @expiration 31_557_600

  require Logger

  use Memento.Table,
    attributes: [:token, :used_tempcode, :grant_date, :client_id, :scopes, :revoked]

  def create(tempcode) do
    token = "T-" <> Nanoid.Secure.generate()

    Memento.transaction!(fn ->
      now = DateTime.utc_now()

      Memento.Query.write(%__MODULE__{
        token: token,
        used_tempcode: tempcode.code,
        grant_date: now,
        client_id: tempcode.client_id,
        scopes: tempcode.scopes,
        revoked: false
      })
    end)

    token
  end

  def revoke(token) do
    Memento.transaction!(fn ->
      accesstoken = Memento.Query.read(__MODULE__, token)
      Memento.Query.write(%{accesstoken | revoked: true})
    end)
  end

  def get_if_valid(token) do
    Memento.transaction!(fn ->
      accesstoken = Memento.Query.read(__MODULE__, token)

      valid =
        !accesstoken.revoked &&
          DateTime.compare(
            DateTime.utc_now(),
            DateTime.add(accesstoken.grant_date, @expiration, :second)
          ) == :lt

      if valid do
        accesstoken
      else
        nil
      end
    end)
  rescue
    err ->
      Logger.warn("accesstoken #{token} not valid: #{inspect(err)}")
      nil
  end

  def get_client_id(token) do
    Memento.transaction!(fn ->
      accesstoken = Memento.Query.read(__MODULE__, token)

      if !is_nil(accesstoken), do: accesstoken.client_id, else: nil
    end)
  end
end