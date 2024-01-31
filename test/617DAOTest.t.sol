// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {BUBDAO} from "../src/617DAO.sol";

contract DAOTest is Test {
    BUBDAO public dao;
    address[] members;

    //ExpectRevert errors
    bytes4 expectedOnlyOwner = bytes4(keccak256("Unauthorized_Only_Owner()"));
    bytes4 expectedOnlyPresident = bytes4(keccak256("Unauthorized_Only_President()"));
    bytes4 expectedOnlyVP = bytes4(keccak256("Unauthorized_Only_VP()"));
    bytes4 expectedOnlyMember = bytes4(keccak256("Unauthorized_Only_Member()"));
    bytes4 expectedAlreadyMember = bytes4(keccak256("AlreadyMember()"));
    bytes4 expectedMeetingNotOpen = bytes4(keccak256("MeetingNotOpen()"));
    bytes4 expectedMeetingIsAlreadyOpen = bytes4(keccak256("MeetingIsAlreadyOpen()"));
    bytes4 expectedAlreadyCheckedIn = bytes4(keccak256("AlreadyCheckedIn()"));
    bytes4 expectedAlreadyVoted = bytes4(keccak256("AlreadyVoted()"));
    bytes4 expectedElectionIsNotOpen = bytes4(keccak256("ElectionIsNotOpen()"));

    function setUp() public {
        dao = new BUBDAO(address(2), members);
    }

    //addMember tests

    function test_addMember() public {
        dao.addMember(address(0));
        assertEq(dao.s_balance(address(0)), 1);
    }

    function test_addMemberWhoIsAlreadyMember() public {
        dao.addMember(address(0));
        vm.expectRevert(expectedAlreadyMember);
        dao.addMember(address(0));
    }

    function test_addMember_onlyOwner() public {
        vm.prank(address(0));
        vm.expectRevert(expectedOnlyOwner);
        dao.addMember(address(0));
    }

    //addVP tests

    function test_addVP() public {
        dao.addMember(address(0));
        dao.addVP(address(0));
        assertEq(dao.s_balance(address(0)), 2);
    }

    function test_addVP_onlyOwner() public {
        vm.prank(address(0));
        vm.expectRevert(expectedOnlyOwner);
        dao.addVP(address(0));
    }

    //newPresident tests
    function test_newPresident() public {
        vm.prank(address(2));
        dao.newPresident(address(0));
        assertEq(dao.s_balance(address(0)), 3);
        assertEq(dao.s_balance(address(2)), 0);
    }

    function test_newPresident_onlyPresident() public {
        vm.prank(address(0));
        vm.expectRevert(expectedOnlyPresident);
        dao.newPresident(address(1));
    }

    //Airdrop tests

    function test_airdrop() public {
        address[] memory test = new address[](2);
        test[0] = address(4);
        test[1] = address(5);
        dao.airdrop(test);
        assertEq(dao.getTokenHolder(address(4)), true);
        assertEq(dao.getTokenHolder(address(5)), true);
    }

    //VPAirdrop tests

    function test_vpAirdrop() public {
        address[] memory addrs = new address[](2);
        addrs[0] = address(0);
        addrs[1] = address(1);
        dao.addMember(address(0));
        dao.addMember(address(1));
        dao.vpAirdrop(addrs);
        assertEq(dao.s_balance(address(0)), 2);
        assertEq(dao.s_balance(address(1)), 2);
    }

    //removeMember tests

    function test_removeMember() public {
        dao.addMember(address(0));
        dao.removeMember(address(0));
        assertEq(dao.s_balance(address(0)), 0);
    }

    //removeVp Tests

    function test_removeVP() public {
        dao.addMember(address(0));
        dao.addVP(address(0));
        dao.removeVP(address(0));
        assertEq(dao.s_balance(address(0)), 0);
    }

    //Impeach Tests

    function test_impeach() public {
        dao.addVP(address(3));
        dao.addVP(address(4));
        vm.prank(address(3));
        dao.impeach();
        vm.prank(address(2));
        dao.impeach();
        assertEq(dao.isElectionOpen(), true);
    }

    function test_impeach_alreadyVoted() public {
        dao.addVP(address(3));
        vm.prank(address(3));
        dao.impeach();
        vm.prank(address(3));
        vm.expectRevert(expectedAlreadyVoted);
        dao.impeach();
    }

    //Not enough votes impeach
    event ImpeachmentFailed(uint256 imepachmentVersion);

    function test_impeach_notEnoughVotes() public {
        dao.addVP(address(3));
        vm.prank(address(3));
        dao.impeach();
        console2.log(dao.getCurrentImpeachment());
        vm.warp(block.timestamp + 8 days);
        vm.prank(address(2));
        vm.expectEmit(false, false, false, false, address(dao));
        emit ImpeachmentFailed(1);
        dao.impeach();
    }

    //Test emits

    function test_addProposals() public {
        dao.addMember(address(0));
        vm.prank(address(0));
        dao.addProposal("test");
        (string memory proposal, , ) = dao.s_proposals(0);
        assertEq(proposal, "test");
    }

    function test_vote() public {
        dao.addMember(address(0));
        vm.prank(address(0));
        dao.addProposal("test");
        vm.prank(address(0));
        dao.vote(0, true);
        (, uint256 votesYa, ) = dao.s_proposals(0);
        assertEq(votesYa, 1);
    }

    function test_votePassed() public {
        dao.addMember(address(0));
        vm.prank(address(0));
        dao.addProposal("test");
        vm.prank(address(0));
        dao.vote(0, true);
        vm.prank(address(2));
        dao.vote(0, true);
        (, uint256 votesYa, ) = dao.s_proposals(0);
        assertGt(votesYa, dao.s_totalTokens() / 2);
    }

    function test_voteFailed() public {
        dao.addMember(address(0));
        vm.prank(address(0));
        dao.addProposal("test");
        vm.prank(address(0));
        dao.vote(0, false);
        vm.prank(address(2));
        dao.vote(0, false);
        (, , uint256 votesNay) = dao.s_proposals(0);
        assertGt(votesNay, dao.s_totalTokens() / 2);
    }

    function test_newMeeting() public {
        vm.prank(address(2));
        dao.newMeeting("test");
        string memory topic = dao.getCurrentMeetingTopic();
        assertEq(topic, "test");
    }

    function test_checkInToClosedMeeting() public {
        vm.prank(address(1));
        vm.expectRevert(expectedMeetingNotOpen);
        dao.checkIn();
    }

    function test_memberAlreadyCheckedIn() public {
        vm.prank(address(2));
        dao.newMeeting("Test");
        vm.prank(address(1));
        dao.checkIn();
        vm.prank(address(1));
        vm.expectRevert(expectedAlreadyCheckedIn);
        dao.checkIn();
    }

    function test_addMemberAfterCheckIns() public {
        for (uint8 i = 0; i < 3; i++) {
            vm.prank(address(2));
            dao.newMeeting("Test Meeting");
            vm.prank(address(1));
            dao.checkIn();
            vm.prank(address(2));
            dao.closeMeeting();
        }
        assertEq(dao.s_balance(address(1)), 1); // Now a member after 3 meetings
    }

    function test_didntAddMemberAfterNotEnoughCheckIns() public {
        for (uint8 i = 0; i < 2; i++) {
            vm.prank(address(2));
            dao.newMeeting("Test Meeting");
            vm.prank(address(1));
            dao.checkIn();
            vm.prank(address(2));
            dao.closeMeeting();
        }
        assertEq(dao.s_balance(address(1)), 0);
    }
}
