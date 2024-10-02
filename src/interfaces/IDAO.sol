// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDAO {
    struct Meeting {
        uint256 blockStarted;
        uint256 timestampStarted;
        string topic;
        address[] attendees;
        bool open;
    }

    struct Member {
        address memberAddress;
        string name;
    }

    struct Proposal {
        string proposal;
        uint256 timeCreated;
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        bool passed;
        uint256 index;
    }

    error AddressCantBeZero();
    error AlreadyBoard();
    error AlreadyMember();
    error AlreadyPresident();
    error AlreadyVP();
    error AlreadyVoted();
    error FaucetAlreadySet();
    error MeetingAlreadyOpen();
    error MeetingNotOpen();
    error MustHaveOnePresident();
    error NamesMustEqualAddresses();
    error NotBoard();
    error NotMember();
    error NotPresident();
    error NotVP();
    error OnlyMember();
    error OnlyPresident();
    error ProposalAlreadyPassed();
    error ProposalEnded();

    event NewPresident(address newPresident);
    event NewProposal(string proposal, uint256 index);
    event NewVP(address newVP);
    event ProposalPassed(uint256 index);

    function addBoard(address _newBoard) external;
    function addMember(address _newMember, string memory _name) external;
    function addMultipleBoard(address[] memory _newBoardMembers) external;
    function addMultipleMembers(address[] memory _newMembers, string[] memory _newNames) external;
    function addPresident(address _newPresident) external;
    function addVP(address _newVP) external;
    function checkIn() external;
    function endMeeting() external;
    function getMeetings() external view returns (Meeting[] memory);
    function getNumberOfMeetingsAttended(address _member) external view returns (uint256);
    function getProposals() external view returns (Proposal[] memory);
    function isCheckedIn(address _member) external view returns (bool);
    function isMeetingOpen() external view returns (bool);
    function isMember(address _member) external view returns (bool);
    function isPresident(address _president) external view returns (bool);
    function membersList() external view returns (Member[] memory);
    function newMeeting(string memory _topic) external;
    function newProposal(string memory _proposal) external;
    function removeBoard(address _board) external;
    function removeMember(address _member) external;
    function removePresident(address _president) external;
    function removeVP(address _vp) external;
    function setFaucet(address _faucet) external;
    function voteForProposal(uint256 _index) external;
}