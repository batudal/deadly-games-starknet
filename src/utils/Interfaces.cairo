%lang starknet

@contract_interface
namespace linear_congruential_generator:
    func get_pseudorandom() -> (num_to_use : felt):
    end
    func add_to_seed(val0 : felt, val1 : felt) -> (num_to_use : felt):
    end
end

@contract_interface
namespace xoroshiro128:
    func next() -> (rnd : felt):
    end

@contract_interface
namespace IController:
    func has_write_access(writer : felt):
    end
end
