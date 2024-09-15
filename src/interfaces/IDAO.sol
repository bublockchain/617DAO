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

    struct Proposal {
        string proposal;
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        bool passed;
        uint256 index;
    }

    event NewPresident(address newPresident);
    event NewVP(address newVP);
    event NewProposal(string proposal, uint256 index);
    event ProposalPassed(uint256 index);

    error OnlyPresident();
    error OnlyMember();
    error FaucetAlreadySet();
    error AlreadyPresident();
    error AlreadyVP();
    error AlreadyBoard();
    error AlreadyMember();
    error NotMember();
    error NotPresident();
    error NotVP();
    error NotBoard();
    error AddressCantBeZero();
    error MustHaveOnePresident();
    error MeetingNotOpen();
    error ProposalEnded();
    error ProposalAlreadyPassed();
    error AlreadyVoted();

    /**
     * @notice Set the address of the faucet becuase the DAO must be deployed first
     * @dev Only able to be called once
     * @dev Only callable by a current president 
     * @param _faucet Address of the faucet contract
     */
    function setFaucet(address _faucet) external;

    /**
     * @notice Add a new president to the DAO
     * @dev Only callable by a current president
     * @param _newPresident Address of new president
     */
    function addPresident(address _newPresident) external;

    /**
     * @notice Add a new VP to the DAO
     * @dev Only callable by a current president
     * @param _newVP Address of new VP
     */
    function addVP(address _newVP) external;

    /**
     * @notice Add a new Board member to the DAO
     * @dev Only callable by a current president
     * @param _newBoard Address of the new Board member
     */
    function addBoard(address _newBoard) external;

    /**
     * @notice Add a new member to the DAO
     * @dev Only callable by a current president
     * @param _newMember Address of the new member
     */
    function addMember(address _newMember) external;

    /**
     * @notice Add multiple board members at one time
     * @dev Only callable by a current president
     * @param _newBoardMembers Array of new board member addresses
     */
    function addMultipleBoard(address[] calldata _newBoardMembers) external;

    /**
     * @notice Add multiple members at one time
     * @dev Only callable by a current president
     * @param _newMembers Array of new member addresses
     */
    function addMultipleMembers(address[] calldata _newMembers) external;

    /**
     * @notice Remove president
     * @dev Must have at least one president at all times
     * @dev Only callable by a current president
     * @param _president Address of president to be removed
     */
    function removePresident(address _president) external;

    /**
     * @notice Remove vp
     * @dev Only callable by a current president
     * @param _vp Address of vp to be removed
     */
    function removeVP(address _vp) external;

    /**
     * @notice Remove a board member from the DAO
     * @dev Only callable by a current president
     * @param _board Address of the board member to be removed
     */
    function removeBoard(address _board) external;

    /**
     * @notice Remove a member from the DAO
     * @dev Only callable by a current president
     * @param _member Address of the member to be removed
     */
    function removeMember(address _member) external;

    /**
     * @notice Check if address is a member of the DAO
     * @param _member Address to check
     */
    function isMember(address _member) external view returns (bool);

    /**
     * @notice Check is address is a president of the DAO
     * @param _president Address to check
     */
    function isPresident(address _president) external view returns (bool);

    /**
     * @notice Create a new meeting
     * @dev Only callable by a current president
     * @param _topic The topic of the meeting
     */
    function newMeeting(string calldata _topic) external;

    /**
     * @notice Allow a member to check in to the current meeting
     * @dev Only callable by members (including board, VP, and president)
     */
    function checkIn() external;

    /**
     * @notice End the current meeting
     * @dev Only callable by a current president
     */
    function endMeeting() external;

    /**
     * @notice Get all meetings
     * @return An array of all meetings
     */
    function getMeetings() external view returns (Meeting[] memory);

    /**
     * @notice Get if most recent meeting is open
     * @return Bool true if meeting is open
     */
    function isMeetingOpen() external view returns (bool);

    /**
     * @notice Check if address has checked into meeting
     * @param _member Address to check if it's checked in to meeting
     * @return bool is member check in
     */
    function isCheckedIn(address _member) external view returns (bool);

    /**
     * @notice Get the number of meetings a member has attended
     * @param _member Address of member to lookup
     */
    function getNumberOfMeetingsAttended(address _member) external view returns (uint256);

    /**
     * @notice Create a new proposal
     * @dev Only callable by members (including board, VP, and president)
     * @param _proposal The text of the proposal
     */
    function newProposal(string calldata _proposal) external;

    /**
     * @notice Get all proposals
     * @return An array of all proposals
     */
    function getProposals() external view returns (Proposal[] memory);

    /**
     * @notice Vote for a specific proposal
     * @dev Only callable by members (including board, VP, and president)
     * @param _index The index of the proposal to vote for
     */
    function voteForProposal(uint256 _index) external;
}