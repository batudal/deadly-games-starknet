%lang starknet

from openzeppelin.token.erc721.ERC721_Mintable_Burnable import constructor
from starkware.cairo.common.math import assert_nn

const DEADLY_PERKS_ADDRESS = (
    0x2Db8c2615db39a5eD8750B87aC8F217485BE11EC)

struct MyStruct:
    member first_member : felt
    member second_member : MyStruct*
end



@l1_handler
func registerPerks{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(
    from_address : felt, 
    user : felt, 
    tokenId : felt,
    formation : felt,
    greed : felt,
    lust : felt,
    wrath : felt,
    gluttony : felt,
    pride : felt,
    envy : felt,
    sloth : felt,
    key : felt,
):
    assert from_address = DEADLY_PERKS_ADDRESS
    


