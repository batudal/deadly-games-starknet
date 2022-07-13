%lang starknet

struct Record:
    member fcker_id : felt
    member lcker_id : felt
    member fcker_count : felt
    member lcker_count : felt
end

@contract_interface
namespace IGreedMark:
    func mint_fcker(user : felt, amount : felt):
    end
    func mint_lcker(user : felt):
    end
    func set_greed_addr(addr : felt):
    end
    func get_user_record(user : felt) -> (record : Record):
    end
end
