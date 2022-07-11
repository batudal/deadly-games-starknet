%lang starknet

from starkware.cairo.common.uint256 import Uint256

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
namespace IDeadlyGames:
    func set_karma_address(karma_address : felt):
    end
    func transcendence_to_dao(dao_address : felt):
    end
    func get_admin_address() -> (admin : felt):
    end
    func mint_karma(amount : Uint256, user : felt):
    end
end

@contract_interface
namespace IGame:
    func emergency_shutdown(to_address : felt):
    end
end

@contract_interface
namespace IKarma:
    func mint(to : felt, amount : Uint256):
    end
    func name() -> (name : felt):
    end
    func owner() -> (owner : felt):
    end
    func symbol() -> (symbol : felt):
    end
    func transferOwnership(newOwner : felt):
    end
end
