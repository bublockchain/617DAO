// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DAO} from "../src/DAO.sol";
import {Faucet} from "../src/Faucet.sol";

contract FaucetTest is Test {
    DAO dao;
    Faucet faucet;
    address tester1 = address(1);
    uint256 faucetBalance = 10e18;

    fallback() payable external {}

    receive() payable external {}

    function setUp() public {
        dao = new DAO();
        faucet = new Faucet(address(dao));
        dao.setFaucet(address(faucet));
        vm.deal(address(faucet), faucetBalance);
    }

    function testMakeFundingRequest_works() public {
        vm.roll(block.number + 4 weeks);

        faucet.makeFundingRequest();
        
        vm.expectRevert(Faucet.TooSoonSinceLastRequest.selector);
        faucet.makeFundingRequest();
    }

    function testMakeFuningRequest_onlyMember() public {
        vm.prank(tester1);
        vm.expectRevert(Faucet.OnlyMember.selector);
        faucet.makeFundingRequest();
    }

    function testInitFunding_onlyDAO() public {
        vm.expectRevert(Faucet.OnlyDAO.selector);
        faucet.initalFundingRequestFromDAO(tester1);
    }

    function testChangeFundingAmount() public {
        uint256 newFundingAmount = 6e17;
        faucet.changeFundingAmount(newFundingAmount);

        assertEq(faucet.getDeafultFundingAmount(), newFundingAmount);
    }

    function testWithdrawFunds_works() public {
        dao.addPresident(tester1);
        assertEq(tester1.balance, 5e17);

        vm.prank(tester1);
        faucet.withdrawFunds();

        assertEq(tester1.balance, faucetBalance);
    }

    function testBalanceCheck_reverts() public {
        testWithdrawFunds_works();

        vm.expectRevert(Faucet.InsufficientBankBalance.selector);
        faucet.makeFundingRequest();
    }


}