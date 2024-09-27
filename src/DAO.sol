// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//////////////////////////////////////////////////////////////////////////////////
// The DAO used by Boston University Blockchain Club 
// Created by @Wezabis, 2024
/*
                                        @                                       
                                    @@@@@@@@@                                   
                                @@@@@@@@@@@@@@@@@                               
                                  @@@@@@@@@@@@@@@@@@@@                          
                                       @@@@@@@@@@@@@@@@@@@                      
                                           @@@@@@@@@@@@@@@@@@@                  
                                               @@@@@@@@@@@@@@@@@@@@             
          @@@                                      .@@@@@@@@@@@@@@@@@@@         
      @@@@@@@@@@@                                       @@@@@@@@@@@@@@@@@@@     
  @@@@@@@@@@@@@@@@@@@                                       @@@@@@@@@@@@@@@@@@@ 
 @   @@@@@@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@@@@@@    @
 @@@@@    @@@@@@@@@@@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@@     @@@@@
 @@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@     @@@@@@@@@
 @@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@   ,@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@ %@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@         @@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@         @@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@         @@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@
  *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      
           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@          
                @@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@              
                    @@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@                   
                        @@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@                       
                             @@@@@@@@@@@ @@@@@@@@@@@                            
                                 @@@@@@@ @@@@@@@                                
                                      @@ @@                                    
 */
//////////////////////////////////////////////////////////////////////////////////

import {IFaucet} from "./interfaces/IFaucet.sol";

contract DAO {

    struct Meeting {
        uint256 blockStarted;
        uint256 timestampStarted;
        string topic;
        address[] attendees;
        bool open;
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

    struct Member {
        address memberAddress;
        string name;
    }

    IFaucet private faucet = IFaucet(payable(address(0)));
    mapping(address => bool) private s_isPresident;
    uint256 private s_presidentCount;
    mapping(address => bool) private s_isVP;
    mapping(address => bool) private s_isBoard;
    mapping(address => bool) private s_isMember;
    Member[] private s_members;
    mapping(address => uint) private s_memberToIndex;
    uint256 private s_totalNumberOfTokens;
    Meeting[] private s_meetings;
    mapping(address => uint256) private s_numberOfMeetingsAttended;
    Proposal[] private s_proposals;
    mapping(uint256 => mapping(address => bool)) private hasVoted;

    uint256 private constant PRESIDENT_TOKENS = 5;
    uint256 private constant VP_TOKENS = 3;
    uint256 private constant BOARD_TOKENS = 2;
    uint256 private constant MEMBERS_TOKENS = 1;
    uint256 private constant PROPOSAL_LENGTH = 7 days;

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
    error MeetingAlreadyOpen();
    error MeetingNotOpen();
    error ProposalEnded();
    error ProposalAlreadyPassed();
    error AlreadyVoted();
    error NamesMustEqualAddresses();

    modifier onlyPresident() {
        if (!s_isPresident[msg.sender]) {
            revert OnlyPresident();
        }
        _;
    }

    modifier onlyMember() {
        if (
            s_isMember[msg.sender] ||
            s_isBoard[msg.sender] ||
            s_isVP[msg.sender] ||
            s_isPresident[msg.sender]
        ) {
             _;
        } else {
            revert OnlyMember();
        }
    }

    constructor() {
        s_isPresident[msg.sender] = true;
        s_presidentCount = 1;
        s_totalNumberOfTokens += PRESIDENT_TOKENS;
        emit NewPresident(msg.sender);
    }

    /**
     * @notice Set the address of the faucet becuase the DAO must be deployed first
     * @dev Only able to be called once
     * @dev Only callable by a current president 
     * @param _faucet Address of the faucet contract
     */
    function setFaucet(address _faucet) external onlyPresident {
        if(address(faucet) != address(0)){
            revert FaucetAlreadySet();
        }

        faucet = IFaucet(payable(_faucet));
    }

    ///////////////////////////////////////////////////////////////////////// 
    /**
     * Membership managment functions
     */
    /////////////////////////////////////////////////////////////////////////

    /**
     * @notice Add a new president to the DAO
     * @dev Only callable by a current president
     * @param _newPresident Address of new president
     */
    function addPresident(address _newPresident) external onlyPresident {
        if (_newPresident == address(0)) {
            revert AddressCantBeZero();
        }
        if (s_isPresident[_newPresident]) {
            revert AlreadyPresident();
        }

        distributeInitalFunds(_newPresident);
        s_isPresident[_newPresident] = true;
        s_presidentCount++;
        s_totalNumberOfTokens += PRESIDENT_TOKENS;

        emit NewPresident(_newPresident);
    }

    /**
     * @notice Add a new VP to the DAO
     * @dev Only callable by a current president
     * @param _newVP Address of new VP
     */
    function addVP(address _newVP) external onlyPresident {
        if (s_isVP[_newVP]) {
            revert AlreadyVP();
        }

        distributeInitalFunds(_newVP);
        s_isVP[_newVP] = true;
        s_totalNumberOfTokens += VP_TOKENS;

        emit NewVP(_newVP);
    }

    /**
     * @notice Add a new Board member to the DAO
     * @dev Only callable by a current president
     * @param _newBoard Address of the new Board member
     */
    function addBoard(address _newBoard) external onlyPresident {
        if (s_isBoard[_newBoard]) {
            revert AlreadyBoard();
        }

        distributeInitalFunds(_newBoard);
        s_isBoard[_newBoard] = true;
        s_totalNumberOfTokens += BOARD_TOKENS;
    }

    /**
     * @notice Add a new member to the DAO
     * @dev Only callable by a current president
     * @param _newMember Address of the new member
     */
    function addMember(address _newMember, string memory _name) external onlyPresident {
        if (s_isMember[_newMember]) {
            revert AlreadyMember();
        }

        distributeInitalFunds(_newMember);
        s_isMember[_newMember] = true;
        s_totalNumberOfTokens += MEMBERS_TOKENS;
        s_members.push(Member(_newMember, _name));
        s_memberToIndex[_newMember] = s_members.length - 1;
    }

    /**
     * @notice Add multiple board members at one time
     * @dev Only callable by a current president
     * @param _newBoardMembers Array of new board member addresses
     */
    function addMultipleBoard(
        address[] calldata _newBoardMembers
    ) external onlyPresident {
        for (uint256 i = 0; i < _newBoardMembers.length; i++) {
            address newBoard = _newBoardMembers[i];

            if (s_isBoard[newBoard]) {
                revert AlreadyBoard();
            }

            distributeInitalFunds(newBoard);
            s_isBoard[newBoard] = true;
            s_totalNumberOfTokens += BOARD_TOKENS;
        }
    }

    /**
     * @notice Add multiple members at one time
     * @dev Only callable by a current president
     * @param _newMembers Array of new member addresses
     */
    function addMultipleMembers(
        address[] calldata _newMembers, 
        string[] calldata _newNames
    ) external onlyPresident {
        if(_newMembers.length != _newNames.length){
            revert NamesMustEqualAddresses();
        }

        for (uint256 i = 0; i < _newMembers.length; i++) {
            address newMember = _newMembers[i];
            string memory newName = _newNames[i];

            if (s_isMember[newMember]) {
                revert AlreadyMember();
            }

            distributeInitalFunds(newMember);
            s_isMember[newMember] = true;
            s_totalNumberOfTokens += MEMBERS_TOKENS;
            s_members.push(Member(newMember, newName));
            s_memberToIndex[newMember] = s_members.length - 1;
        }
    }

    /**
     * @notice Internal function to distribute intial funds to members if they have a new wallet
     * @param _addedMember Address to potentially distribute funds too
     */
    function distributeInitalFunds(address _addedMember) internal {
        faucet.initalFundingRequestFromDAO(_addedMember);
    }

    /**
     * @notice Remove president
     * @dev Must have at least one president at all times
     * @dev Only callable by a current president
     * @param _president Address of president to be removed
     */
    function removePresident(address _president) external onlyPresident {
        if (!s_isPresident[_president]) {
            revert NotPresident();
        }

        if (s_presidentCount == 1) {
            revert MustHaveOnePresident();
        }

        s_isPresident[_president] = false;
        s_presidentCount--;
        s_totalNumberOfTokens -= PRESIDENT_TOKENS;
    }

    /**
     * @notice Remove vp
     * @dev Only callable by a current president
     * @param _vp Address of vp to be removed
     */
    function removeVP(address _vp) external onlyPresident {
        if (!s_isVP[_vp]) {
            revert NotVP();
        }

        s_isVP[_vp] = false;
        s_totalNumberOfTokens -= VP_TOKENS;
    }

    /**
     * @notice Remove a board member from the DAO
     * @dev Only callable by a current president
     * @param _board Address of the board member to be removed
     */
    function removeBoard(address _board) external onlyPresident {
        if (!s_isBoard[_board]) {
            revert NotBoard();
        }

        s_isBoard[_board] = false;
        s_totalNumberOfTokens -= BOARD_TOKENS;
    }

    /**
     * @notice Remove a member from the DAO
     * @dev Only callable by a current president
     * @param _member Address of the member to be removed
     */
    function removeMember(address _member) external onlyPresident {
        if (!s_isMember[_member]) {
            revert NotMember();
        }

        s_isMember[_member] = false;
        s_totalNumberOfTokens -= MEMBERS_TOKENS;

        s_members[s_memberToIndex[_member]] = s_members[s_members.length - 1];
        s_members.pop();
    }

    /**
     * @notice Check if address is a member of the DAO
     * @param _member Address to check
     */
    function isMember(address _member) external view returns (bool) {
        if (
            s_isMember[_member] ||
            s_isBoard[_member] ||
            s_isVP[_member] ||
            s_isPresident[_member]
        ) {
             return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Check is address is a president of the DAO
     * @param _president Address to check
     */
    function isPresident(address _president) external view returns (bool) {
        return s_isPresident[_president];
    }

    /**
     * @notice Get list of member names and addresses for easier frontend managament
     * @return Array of Member structs
     */
    function membersList() external view returns (Member[] memory) {
        return s_members;
    }


    //////////////////////////////////////////////////////////////////////////////////
    /**
     * Meeting related functions
     */
    //////////////////////////////////////////////////////////////////////////////////


    /**
     * @notice Create a new meeting
     * @dev Only callable by a current president
     * @param _topic The topic of the meeting
     */
    function newMeeting(string calldata _topic) external onlyPresident {
        if(s_meetings.length > 0){
            if(s_meetings[s_meetings.length].open == true){
                revert MeetingAlreadyOpen();
            }
        }

        address[] memory newAttendees;
        s_meetings.push(Meeting(block.number, block.timestamp, _topic, newAttendees, true));
    }

    /**
     * @notice Allow a member to check in to the current meeting
     * @dev Only callable by members (including board, VP, and president)
     */
    function checkIn() external onlyMember {
        Meeting storage temp = s_meetings[s_meetings.length - 1];

        if(!temp.open){
            revert MeetingNotOpen();
        }

        temp.attendees.push(msg.sender);
        s_numberOfMeetingsAttended[msg.sender] = s_numberOfMeetingsAttended[msg.sender] + 1;
    }

    /**
     * @notice End the current meeting
     * @dev Only callable by a current president
     */
    function endMeeting() external onlyPresident {
        Meeting storage temp = s_meetings[s_meetings.length - 1];

        if(!temp.open){
            revert MeetingNotOpen();
        }

        temp.open = false;
    }

    /**
     * @notice Get all meetings
     * @return An array of all meetings
     */
    function getMeetings() external view returns (Meeting[] memory) {
        return s_meetings;
    }

    /**
     * @notice Get if most recent meeting is open
     * @return Bool true if meeting is open
     */
    function isMeetingOpen() external view returns (bool) {
        return s_meetings[s_meetings.length - 1].open;
    }

    /**
     * @notice Check if address has checked into meeting
     * @param _member Address to check if it's checked in to meeting
     * @return bool is member check in
     */
    function isCheckedIn(address _member) external view returns (bool) {
        Meeting storage temp = s_meetings[s_meetings.length - 1];

        for(uint x; x < temp.attendees.length; x++){
            if(temp.attendees[x] == _member){
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Get the number of meetings a member has attended
     * @param _member Address of member to lookup
     */
    function getNumberOfMeetingsAttended(address _member) external view returns (uint256) {
        return s_numberOfMeetingsAttended[_member];
    }


    //////////////////////////////////////////////////////////////////////////////////
    /**
     * Proposal related functions
     */
    //////////////////////////////////////////////////////////////////////////////////


    /**
     * @notice Create a new proposal
     * @dev Only callable by members (including board, VP, and president)
     * @param _proposal The text of the proposal
     */
    function newProposal(string calldata _proposal) external onlyMember {
        s_proposals.push(Proposal(_proposal, block.timestamp, block.number, block.number+PROPOSAL_LENGTH, 0, false, s_proposals.length));
        emit NewProposal(_proposal, s_proposals.length - 1);
    }

    /**
     * @notice Get all proposals
     * @return An array of all proposals
     */
    function getProposals() external view returns (Proposal[] memory) {
        return s_proposals;
    }

    /**
     * @notice Vote for a specific proposal
     * @dev Only callable by members (including board, VP, and president)
     * @param _index The index of the proposal to vote for
     */
    function voteForProposal(uint256 _index) external onlyMember {
        Proposal storage temp = s_proposals[_index];

        if(temp.endBlock < block.number){
            revert ProposalEnded();
        }

        if(hasVoted[_index][msg.sender]){
            revert AlreadyVoted();
        }

        if(temp.passed){
            revert ProposalAlreadyPassed();
        }


        if(s_isPresident[msg.sender]){
            temp.votesFor += PRESIDENT_TOKENS;
        } else if(s_isVP[msg.sender]){
            temp.votesFor += VP_TOKENS;
        } else if(s_isBoard[msg.sender]){
            temp.votesFor += BOARD_TOKENS;
        } else {
            temp.votesFor += MEMBERS_TOKENS;
        }

        hasVoted[_index][msg.sender] = true;

        if(temp.votesFor > (s_totalNumberOfTokens / 2)){
            temp.passed = true;
            emit ProposalPassed(_index);
        }
    }
}
