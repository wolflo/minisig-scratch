pragma solidity 0.6.6;

// huff reference version:
// - change all bools to uint8
// - change signers to an array
contract MiniSig {
    uint256 public nonce;
    mapping(address => uint256) public signers;

    uint8 public immutable threshold;
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant EXECUTE_TYPEHASH = keccak256("Execute(address target,uint256 value,uint256 callGas,uint256 nonce,bool useDelegateCall,bytes data)");

    receive () external payable {}
    fallback () external payable {}

    constructor(uint8 _threshold, address[] memory _signers) public {
        require(_signers.length >= _threshold, "signers-invalid-length");

        uint256 chainId;
        assembly { chainId := chainid() }
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,uint256 chainId,uint256 deployBlock,address verifyingContract)"),
            keccak256("MiniSig"),
            chainId,
            block.number,   // differentiates create2 deploys to same address
            address(this)
        ));

        threshold = _threshold;
        for (uint256 i = 0; i < _signers.length; i++) {
            // instead of this check, huff version would require first sig != 0
            // and sigs in ascending order, which makes execute check more efficient
            require(_signers[i] != address(0), "invalid-signer-0");
            signers[_signers[i]] = 1;
        }
    }

    function execute(
        address _target,
        uint256 _value,
        uint256 _callGas,
        bool _useDelegateCall,
        bytes calldata _data,
        bytes calldata _sigs
    )
        external
        payable
    {
        // max(uint8) * 65 << max(uint256), so no overflow check
        require(_sigs.length >= uint256(threshold) * 65, "sigs-invalid-length");

        uint256 initialNonce = nonce;
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                EXECUTE_TYPEHASH,
                _target,
                _value,
                _callGas,
                initialNonce,
                _useDelegateCall,
                keccak256(_data)
            ))
        ));

        for (uint256 i = 0; i < threshold; i++) {
            // sig should be 65 bytes total, {32 byte r}{32 byte s}{1 byte v}
            address addr = ecrecover(digest, uint8(_sigs[65]), _sigs[0], _sigs[32]);
            require(signers[addr] == 1, "invalid-signer");
        }

        uint256 endNonce = initialNonce + 1;
        nonce = endNonce;
        bool success;
        if (_useDelegateCall) {
            // require(_value == 0)
            (success,) = _target.delegatecall{gas: _callGas}(_data);
        } else {
            (success,) = _target.call{gas: _callGas, value: _value}(_data);
        }
        require(success, "call-failure");

        // prevents changing the nonce storage slot (and reentrancy)
        // this is less interesting in the solidity version, because we
        // need to store signers anyway
        require(nonce == endNonce, "oops");
    }
}