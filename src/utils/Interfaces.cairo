%lang starknet

@contract_interface
namespace linear_congruential_generator:
    func get_pseudorandom() -> (num_to_use : felt):
    end
    func add_to_seed(val0 : felt, val1 : felt) -> (num_to_use : felt):
    end
end
