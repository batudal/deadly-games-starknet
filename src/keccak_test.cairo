%lang starknet

from starkware.cairo.common.cairo_keccak.keccak import keccak, finalize_keccak

const prefix = 'formation :'
const token_id = 0
let inputs : felt* = alloc()
assert inputs[0] = prefix
assert inputs[1] = token_id
keccak(inputs, 64)
finalize_keccak()
