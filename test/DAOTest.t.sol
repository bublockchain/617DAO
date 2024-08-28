// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DAO} from "../src/DAO.sol";
import {Faucet} from "../src/Faucet.sol";

contract DAOTest is Test {
    DAO dao;
    Faucet faucet;
    address tester1 = address(1);
    address[] testers = [address(1), address(2), address(3)];

    function setUp() public {
        dao = new DAO();
        faucet = new Faucet(address(dao));
        dao.setFaucet(address(faucet));
        vm.deal(address(faucet), 10e18);
    }

    function testConstructor_works() public view {
        assertEq(dao.isPresident(address(this)), true);
    }

    function testSetFaucet_cantSetTwice() public {
        vm.expectRevert(DAO.FaucetAlreadySet.selector);
        dao.setFaucet(address(0));
    }

    function testAddPresident_works() public {
        dao.addPresident(tester1);

        assertEq(tester1.balance, 5e17);
        assertEq(dao.isPresident(tester1), true);
    }

    function testAddPresident_CantBeZero() public {
        vm.expectRevert(DAO.AddressCantBeZero.selector);
        dao.addPresident(address(0));
    }

    function testAddPresident_AlreadyPresident() public {
        vm.expectRevert(DAO.AlreadyPresident.selector);
        dao.addPresident(address(this));
    }

    function testAddVP_works() public {
        dao.addVP(tester1);

        assertEq(tester1.balance, 5e17);
        assertEq(dao.isMember(tester1), true);
    }

    function testAddVP_AlreadyVP() public {
        testAddVP_works();

        vm.expectRevert(DAO.AlreadyVP.selector);
        dao.addVP(tester1);
    }

    function testAddBoard_works() public {
        dao.addBoard(tester1);
        assertEq(tester1.balance, 5e17);
        assertEq(dao.isMember(tester1), true);
    }

    function testAddBoard_AlreadyBoard() public {
        testAddBoard_works();

        vm.expectRevert(DAO.AlreadyBoard.selector);
        dao.addBoard(tester1);
    }

    function testAddMember_works() public {
        dao.addMember(tester1);
        assertEq(tester1.balance, 5e17);
        assertEq(dao.isMember(tester1), true);
    }

    function testAddMember_AlreadyMember() public {
        testAddMember_works();

        vm.expectRevert(DAO.AlreadyMember.selector);
        dao.addMember(tester1);
    }

    function testAddMultipleBoard_works() public {
        dao.addMultipleBoard(testers);
        assertEq(dao.isMember(testers[0]), true);
        assertEq(dao.isMember(testers[1]), true);
        assertEq(dao.isMember(testers[2]), true);
        assertEq(testers[0].balance, 5e17);
        assertEq(testers[1].balance, 5e17);
        assertEq(testers[2].balance, 5e17);
    }

    function testAddMultipleMembers_works() public {
        dao.addMultipleMembers(testers);
        assertEq(dao.isMember(testers[0]), true);
        assertEq(dao.isMember(testers[1]), true);
        assertEq(dao.isMember(testers[2]), true);
        assertEq(testers[0].balance, 5e17);
        assertEq(testers[1].balance, 5e17);
        assertEq(testers[2].balance, 5e17);
    }

    function testRemovePresident_works() public {
        testAddPresident_works();

        dao.removePresident(tester1);
        assertEq(dao.isPresident(tester1), false);
    }

    function testRemovePresident_NotPresident() public {
        vm.expectRevert(DAO.NotPresident.selector);
        dao.removePresident(tester1);
    }

    function testRemovePresident_MustHaveOne() public {
        vm.expectRevert(DAO.MustHaveOnePresident.selector);
        dao.removePresident(address(this));
    }

    function testRemoveVP_works() public {
        testAddVP_works();

        dao.removeVP(tester1);
        assertEq(dao.isMember(tester1), false);
    }

    function testRemoveBoard_works() public {
        testAddBoard_works();

        dao.removeBoard(tester1);
        assertEq(dao.isMember(tester1), false);
    }

    function testRemoveMember_works() public {
        testAddMember_works();

        dao.removeMember(tester1);
        assertEq(dao.isMember(tester1), false);
    }

    function testNewMeeting_works() public {
        string memory test1 = "test1";
        dao.newMeeting("test1");
        DAO.Meeting[] memory temp = dao.getMeetings();
        assertEq(temp[0].topic, test1);
    }

    function testCheckIn_works() public {
        testNewMeeting_works();
        testAddMember_works();

        vm.prank(tester1);
        dao.checkIn();

        DAO.Meeting[] memory temp = dao.getMeetings();
        assertEq(temp[0].attendees[0], tester1);
        assertEq(dao.getNumberOfMeetingsAttended(tester1), 1);
    }

    function testCheckIn_MeetingNotOpen() public {
        testNewMeeting_works();
        testAddMember_works();
        dao.endMeeting();
        

        vm.prank(tester1);
        vm.expectRevert(DAO.MeetingNotOpen.selector);
        dao.checkIn();
    }

    function testEndMeeting_MeetingNotOpen() public {
        testNewMeeting_works();
        dao.endMeeting();

        vm.expectRevert(DAO.MeetingNotOpen.selector);
        dao.endMeeting();
    }

    event NewProposal(string proposal, uint index);
    function  testnewProposal_works() public {
        string memory test1 = "test1";

        vm.expectEmit();
        emit NewProposal(test1, 0);
        dao.newProposal(test1);

        DAO.Proposal[] memory temp = dao.getProposals();
        assertEq(temp[0].proposal, test1);
    }

    event ProposalPassed(uint index);
    function testVoteForProposal_works() public {
        testnewProposal_works();

        vm.expectEmit();
        emit ProposalPassed(0);
        dao.voteForProposal(0);
    }

    function testVoteForProposal_Ended() public {
        testnewProposal_works();

        vm.roll(block.number + 8 days);

        vm.expectRevert(DAO.ProposalEnded.selector);
        dao.voteForProposal(0);
    }

    function testVoteProposal_AlreadyPassed() public {
        testnewProposal_works();
        testAddMember_works();
        dao.voteForProposal(0);

        vm.prank(tester1);
        vm.expectRevert(DAO.ProposalAlreadyPassed.selector);
        dao.voteForProposal(0);
    }

    function testVoteProposal_AlreadyVoted() public {
        testVoteForProposal_works();
        
        vm.expectRevert(DAO.AlreadyVoted.selector);
        dao.voteForProposal(0);
    }
    
}