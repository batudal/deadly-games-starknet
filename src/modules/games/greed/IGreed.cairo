%lang starknet

@contract_interface
namespace IGreed:
    func greed(ticket_amount : felt):
    end
    func set_addresses(
        token_address : felt,
        deadly_games_address : felt,
        pseudo_address : felt,
        greed_mark_address : felt,
    ):
    end
    func claim():
    end
    func get_user_win_count(user : felt) -> (count : felt):
    end
end
