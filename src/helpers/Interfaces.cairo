%lang starknet

@contract_interface
namespace ILCG:
    func get_pseudorandom() -> (num_to_use : felt):
    end
    func add_to_seed(val0 : felt, val1 : felt) -> (num_to_use : felt):
    end
end

@contract_interface
namespace IXoroshiro128:
    func next() -> (rnd : felt):
    end
end

@contract_interface
namespace IController:
    func has_write_access(writer : felt):
    end
end

@contract_interface
namespace IERC1155:
end

@contract_interface
namespace IDeadlyGames:
    func mint_karma(amount : Uint256, user : felt):
    end
end

@contract_interface
namespace IGame:
    func emergency_shutdown(to_address : felt):
    end
end
