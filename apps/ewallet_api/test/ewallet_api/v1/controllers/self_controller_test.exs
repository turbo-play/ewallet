defmodule EWalletAPI.V1.SelfControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletDB.{User, Account}

  describe "/me.get" do
    test "responds with user data" do
      response = client_request("/me.get")

      assert response["success"]
      assert response["data"]["username"] == @username
    end
  end

  describe "/me.get_settings" do
    test "responds with a list of minted_tokens" do
      response = client_request("/me.get_settings")

      assert response["success"]
      assert Map.has_key?(response["data"], "minted_tokens")
      assert is_list(response["data"]["minted_tokens"])
    end
  end

  describe "/me.list_balances" do
    test "responds with a list of balances" do
      account        = Account.get_master_account()
      master_balance = Account.get_primary_balance(account)
      user           = get_test_user()
      user_balance   = User.get_primary_balance(user)
      btc            = insert(:minted_token, %{symbol: "BTC"})
      play            = insert(:minted_token, %{symbol: "PLAY"})

      mint!(btc)
      mint!(play)

      transfer!(master_balance.address, user_balance.address, btc, 150_000 * btc.subunit_to_unit)
      transfer!(master_balance.address, user_balance.address, play, 12_000 * play.subunit_to_unit)

      response = client_request("/me.list_balances")

      assert response == %{
        "version" => "1",
        "success" => true,
        "data" => %{
          "object" => "list",
          "data" => [
            %{
              "object" => "address",
              "address" => user_balance.address,
              "balances" => [
                %{
                  "object" => "balance",
                  "amount" => 150_000 * btc.subunit_to_unit,
                  "minted_token" => %{
                    "name" => btc.name,
                    "object" => "minted_token",
                    "subunit_to_unit" => btc.subunit_to_unit,
                    "symbol" => btc.symbol,
                    "id" => btc.friendly_id,
                    "metadata" => %{},
                    "encrypted_metadata" => %{}
                  }
                },
                %{
                  "object" => "balance",
                  "amount" => 12_000 * play.subunit_to_unit,
                  "minted_token" => %{
                    "name" => play.name,
                    "object" => "minted_token",
                    "subunit_to_unit" => play.subunit_to_unit,
                    "symbol" => play.symbol,
                    "id" => play.friendly_id,
                    "metadata" => %{},
                    "encrypted_metadata" => %{}
                  }
                }
              ]
            }
          ]
        }
      }
    end
  end
end
