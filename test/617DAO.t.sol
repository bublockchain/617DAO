// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {BUBDAO} from "../src/617DAO.sol";
import {Deploy617DAO} from "../script/Deploy617DAO.s.sol";

contract DAOTest is Test {
    BUBDAO public dao;
    address[] members;

    function setUp() public {
        Deploy617DAO deploy = new Deploy617DAO();
        dao = deploy.run(address(this), members);
    }

    function test_addMember() public {
        dao.addMember(address(0));
        assertEq(dao.s_balance(address(0)), 1);
    }

    function test_addVP() public {
        dao.addMember(address(0));
        dao.addVP(address(0));
        assertEq(dao.s_balance(address(0)), 2);
    }

    function test_addProposals() public {
        vm.prank(address(this));
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
        vm.prank(address(this));
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
        vm.prank(address(this));
        dao.vote(0, false);
        (, , uint256 votesNay) = dao.s_proposals(0);
        console2.log(votesNay);
        assertGt(votesNay, dao.s_totalTokens() / 2);
    }

    function test_newMeeting() public {
        dao.newMeeting("test");
        string memory topic = dao.getCurrentMeetingTopic();
        assertEq(topic, "test");
    }

    // function test_airdrop() public {
    //    address[] memory addrs = new address[](2);
    //    addrs[0] = address(0);
    //    addrs[1] = address(1);
    //    dao.airdrop(addrs);
    //    assertEq(dao.s_balance(address(0)), 1);
    //    assertEq(dao.s_balance(address(1)), 1);
    // }

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

    function test_removeMember() public {
        dao.addMember(address(0));
        dao.removeMember(address(0));
        assertEq(dao.s_balance(address(0)), 0);
    }

    function test_removeVP() public {
        dao.addMember(address(0));
        dao.addVP(address(0));
        dao.removeVP(address(0));
        assertEq(dao.s_balance(address(0)), 0);
    }

    function test_newPresident() public {
        dao.newPresident(address(0));
        assertEq(dao.s_balance(address(0)), 3);
        assertEq(dao.s_balance(address(this)), 0);
    }

    function test_unauthorizedAccess_addMember() public {
        vm.expectRevert(bytes("UnauthorizedOwner"));
        vm.prank(address(3));
        dao.addMember(address(0));
    }

    function test_unauthorizedAccess_newMeeting() public {
        vm.expectRevert(bytes("UnauthorizedPresident"));
        vm.prank(address(2));
        dao.newMeeting("Unauthorized Test");
    }

    function test_unauthorizedAccess_closeMeeting() public {
        vm.expectRevert(bytes("UnauthorizedPresident"));
        vm.prank(address(1));
        dao.closeMeeting();
    }

    function test_unauthorizedAccess_removeMember() public {
        dao.addMember(address(0));
        vm.expectRevert(bytes("UnauthorizedOwner"));
        vm.prank(address(0));
        dao.removeMember(address(0));
    }

    function test_unauthorizedAccess_removeVP() public {
        dao.addMember(address(0));
        dao.addVP(address(0));
        vm.expectRevert(bytes("UnauthorizedOwner"));
        vm.prank(address(0));
        dao.removeVP(address(0));
    }

    function test_notYetMembers() public {
        for (uint8 i = 0; i < 3; i++) {
            dao.newMeeting("Test Meeting");
            vm.prank(address(1));
            dao.checkIn();
            dao.closeMeeting();
        }
        assertEq(dao.s_balance(address(1)), 1); // Now a member after 3 meetings
    }
}
