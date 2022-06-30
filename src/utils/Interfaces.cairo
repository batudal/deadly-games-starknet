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
