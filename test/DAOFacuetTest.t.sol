// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {DAOFaucet} from "../src/DAOFaucet.sol";
import {BUBDAO} from "../src/617DAO.sol";

contract DAOFaucetTest is Test {
    DAOFaucet faucet;
    BUBDAO dao;
    address[] members;
    address president = address(0);

    event Deposit(address indexed sender, uint256 amount);
    event Funding(address indexed sentTo, bytes data);
    event DrainedFunds();

    bytes4 expectedUnauthorizedOnlyOwner = bytes4(keccak256("Unauthorized_OnlyOwner()"));
    bytes4 expectedOnlyDAOMembersCanRequestFunds = bytes4(keccak256("OnlyDAOMembersCanRequestFunds()"));
    bytes4 expectedAlreadyCompletedRequest = bytes4(keccak256("AlreadyCompletedRequest()"));
    bytes4 expectedFailedTransaction = bytes4(keccak256("FailedTransaction()"));
    bytes4 expectedNoRequestFound = bytes4(keccak256("NoRequestFound()"));

    function setUp() public {
        dao = new BUBDAO(president, members);
        faucet = new DAOFaucet(address(dao));
    }

    //Recieve test
    function test_recieve() public {
        vm.deal(address(1), 1 ether);
        vm.prank(address(1));
        vm.expectEmit(true, false, false, true, address(faucet));
        emit Deposit(address(1), 0.5 ether);
        (bool success, ) = address(faucet).call{value: 0.5 ether}("");
        assertTrue(success);
    }
}
