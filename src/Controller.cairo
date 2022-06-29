%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address

@storage_var
func admin() -> (address : felt):
end

@storage_var
func id_to_address(id : felt) -> (address : felt):
end

@storage_var
func address_to_id(address : felt) -> (id : felt):
end

@storage_var
func write_access(writer : felt, written : felt) -> (bool : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    admin_address : felt
):
    admin.write(admin_address)
    return ()
end

func only_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (local caller) = get_caller_address()
    let (current) = admin.read()
    assert caller = current
    return ()
end

@external
func set_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    admin_address : felt
):
    admin.write(admin_address)
    return ()
end

@external
func set_implementation{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id : felt, new_address : felt
):
    id_to_address.write(id, new_address)
    address_to_id(new_address, id)
    return ()
end

@external
func set_write_access{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    writer : felt, written : felt
):
    only_admin()
    write_access.write(writer, writtern)
    return ()
end

@view
func has_write_access{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    writer : felt
):
    alloc_locals
    let (caller) = get_caller_address()
    let (id) = address_to_id.read(caller)
    let (local current_address) = id_to_address.read(id)
    assert current_address = caller

    let (caller_id) = address_to_id.read(writer)
    let (local active_address) = id_to_address.read(caller_id)
    assert active_address = caller_id

    let (bool) = can_write_to.read(module_id_attempting_to_write, module_id_being_written_to)
    assert_not_zero(bool)
    return ()
end
