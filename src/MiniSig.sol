pragma solidity 0.6.6;

// The point of this contract is to provide an executable solidity reference
// implementation that will approximate the huff implementation. The result
// is exceptionally bad solidity, and this should not be used except for
// comparison with huff impl. It will also not match the huff particularly
// well, because the huff uses an approach that can't be built in solidity.
// Note that instead of a nonce, each signature should include an expiration
// block number when it becomes invalid. This allows the huff implementation
// to maintain no state whatsoever.
contract MiniSig {

    enum CallType {
        Call,
        DelegateCall
    }

    address[] internal signers;         // approved signers
    uint8 public immutable threshold;   // minimum required signers

    // --- EIP712 ---
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 internal constant DOMAIN_SEPARATOR_TYPEHASH = keccak256("EIP712Domain(uint256 chainId,uint256 deployBlock,address verifyingContract)");
    bytes32 internal constant EXECUTE_TYPEHASH = keccak256("Execute(uint8 callType,address target,uint256 value,uint256 expiryBlock,bytes data)");

    // recieve ether only if calldata is empty
    receive () external payable {}

    constructor(uint8 _threshold, address[] memory _signers) public {
        require(_signers.length >= _threshold, "signers-invalid-length");

        uint256 chainId;
        assembly { chainId := chainid() }
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            DOMAIN_SEPARATOR_TYPEHASH,
            chainId,
            block.number,   // differentiates create2 deploys to same address
            address(this)
        ));

        address prevSigner = address(0);
        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            require(signer > prevSigner, "invalid-signer-order");
            prevSigner = signer;
        }

        threshold = _threshold;
        signers = _signers;
    }

    function execute(
        CallType _callType,
        address _target,
        uint256 _value,
        uint256 _expiryBlock,
        bytes calldata _data,
        bytes calldata _sigs
    )
        external
        payable
    {
        // max(uint8) * 65 << max(uint256), so no overflow check
        require(block.number < _expiryBlock, "invalid-block");
        require(_sigs.length >= uint256(threshold) * 65, "sigs-invalid-length");

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                EXECUTE_TYPEHASH,
                _callType,
                _target,
                _value,
                _expiryBlock,
                keccak256(_data)
            ))
        ));

        // Note: a single invalid sig will cause a revert, even if there are
        // `>= threshold` valid sigs. But, an invalid sig after `threshold`
        // valid sigs is ignored
        uint256 sigIdx = 0;
        uint256 signerIdx = 0;
        for (uint256 i = 0; i < threshold; i++) {
            // sig should be 65 bytes total, {32 byte r}{32 byte s}{1 byte v}
            address addr = ecrecover(digest, uint8(_sigs[sigIdx + 65]), _sigs[sigIdx], _sigs[sigIdx + 32]);
            sigIdx += 65;

            // TODO lol
            // for current signerIdx to end of signers, check each signer against
            // recovered address.
            // If we exhaust the list without a match, revert
            // if we find a match, signerIdx = match index, continue looping through sigs
            bool elem = false;
            for (uint256 j = signerIdx; j < signers.length && !elem; j++) {
                if (addr == signers[j]) {
                    elem = true;
                    signerIdx = j;
                    // break
                }
            }
            require(elem, "not-signer");
            elem = false;
        }

        // TODO: return data?
        bool success;
        if (_callType == CallType.Call) {
            (success,) = _target.call{value: _value}(_data);
        }
        if (_callType == CallType.DelegateCall) {
            // TODO: prevent delegatecall value confusion?
            // require(_value == 0 || _value == msg.value)
            (success,) = _target.delegatecall(_data);
        }
        require(success, "call-failure");
    }

    function allSigners() external view returns (address[] memory) {
        return signers;
    }
}
