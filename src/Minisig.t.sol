pragma solidity ^0.5.15;

import "ds-test/test.sol";

import "./Minisig.sol";

contract MinisigTest is DSTest {
    Minisig minisig;

    function setUp() public {
        minisig = new Minisig();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
