# MiniSig
A minimal multisig written in Huff.
- By taking the constructor args (signers, threshold, and (maybe) EIP712 hashes) and encoding them into the runtime code, the only `sload`s and `sstore`s are for the nonce.
- Probably would be significantly cheaper that any existing multisig, including those that use the proxy pattern
- Firmly in the forks-are-the-only-valid-upgrades camp - if you want to change something, deploy a new one

# Challenges
- can not have a solidity reference implementation, because solidity only supports value types as immutables (as of 0.6.9)
- can not compare yul vs. huff, because it's too different from silentcicero's yul multisig
- formal verification becomes difficult when the runtime bytecode is different in every instance
