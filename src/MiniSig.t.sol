pragma solidity ^0.6.0;

import "ds-test/test.sol";

import "./MiniSig.sol";

contract MiniSigTest is DSTest {
    MiniSig msig;
    uint8 constant threshold = 2;
    address[] signers = [address(1), address(this)];
    bytes sig = hex'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbffaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbff';

    function setUp() public {
        msig = new MiniSig(threshold, signers);
    }

    function testConstructor() public {
        assertEq(uint(msig.threshold()), uint(threshold));
        for (uint i = 0; i < signers.length; i++) {
            assertEq(msig.signers(signers[i]), 1);
        }
    }

    function testExecute() public {
        msig.execute(false, address(0), 100, gasleft(), bytes(''), sig);
    }

}
