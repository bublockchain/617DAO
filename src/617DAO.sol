// SPDX-License-Identifier: CC-BY-1.0
pragma solidity ^0.8.20;

//@title The Boston University Blockchain Club DAO
//@author Wes Jorgensen, @Wezabis on twtr
//@notice This contract is a simple DAO for the Boston University Blockchain Club

contract BUBDAO {
    // Set to BUB Wallet Address
    address public s_owner;
    address public s_president;

    // Token balances and total tokens
    mapping(address => uint8) public s_balance;
    mapping(address => uint8) public s_balance;
    uint public s_totalTokens;

    // Constants
    uint8 constant PRESIDENT_TOKENS = 3;
    uint8 constant VP_TOKENS = 2;
    uint8 constant MEMBER_TOKENS = 1;
    uint8 constant MEETINGS_REQUIRED_TO_JOIN = 3;

    // Errors
    error Unauthorized_Only_Owner();
    error Unauthorized_Only_President();
    error Unauthorized_Only_VP();
    error Unauthorized_Only_Member();
    error AlreadyMember();
    error MeetingNotOpen();
    error MeetingIsAlreadyOpen();
    error AlreadyCheckedIn();
    error AlreadyVoted();

    // Structs
    struct Proposal {
        string proposal;
        uint votesYa;
        uint votesNay;
    }

    struct Meeting {
        uint date;
        string topic;
        address[] attendees;
        bool open;
    }

    struct Impeachment {
        address newPresident;
        uint256 startTime;
        uint8 votes;
    }

    // State variables
    mapping(address => uint) private s_notYetMembers;
    mapping(address => uint) private s_notYetMembers;
    mapping(uint => mapping(address => bool)) private s_votes;
    mapping(address => uint) private s_openImpeachments;
    Proposal[] public s_proposals;
    Meeting private s_currentMeeting;
    Meeting[] private s_pastMeetings;
    Impeachment[] private s_impeachments;

    // Events
    event NewProposal(string proposal);
    event ProposalPassed(string proposal);
    event ProposalFailed(string proposal);

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != s_owner) {
            revert UnauthorizedOwner();
        }
        _;
    }

    modifier onlyMember() {
        if (s_balance[msg.sender] == 0) {
            revert UnauthorizedMember();
        }
        _;
    }

    modifier onlyVP() {
        if (s_balance[msg.sender] < VP_TOKENS) {
            revert UnauthorizedVP();
        }
        _;
    }

    modifier onlyPresident() {
        if (msg.sender != s_president) {
            revert UnauthorizedPresident();
        }
        _;
    }

    //@notice Constructor sets the owner and president of the DAO
    constructor(address _president, address[] memory _members) {
        s_owner = msg.sender;
        s_president = _president;
        s_balance[msg.sender] = PRESIDENT_TOKENS;
        s_totalTokens += PRESIDENT_TOKENS;
        airdrop(_members);
    }

    // All adding and removing members functions

    //@notice adds members to DAO
    function addMember(address _member) public onlyOwner {
        if (s_balance[_member] != 0) {
        if (s_balance[_member] != 0) {
            revert AlreadyMember();
        }
        s_balance[_member] = MEMBER_TOKENS;
        s_totalTokens += MEMBER_TOKENS;
    }

    //@notice adds VP to DAO
    function addVP(address _vp) public onlyOwner {
        if (s_balance[_vp] == 1) {
            s_balance[_vp] = VP_TOKENS;
            s_totalTokens += VP_TOKENS;
        } else {
            revert UnauthorizedOwner();
        }
    }

    //@notice adds President to DAO and removes old president
    function newPresident(address _president) public onlyPresident {
        s_balance[_president] = PRESIDENT_TOKENS;
        s_balance[s_president] = 0;
        s_president = _president;
    }

    //@notice airdrops governance tokens to a list of new members
    function airdrop(address[] memory list) private onlyOwner {
        for (uint i = 0; i < list.length; ++i) {
            s_balance[list[i]] = 1;
        }
    }

    //@notice airdrops number tokens for VP to a list of new VPs
    function vpAirdrop(address[] calldata list) public onlyOwner {
        for (uint i = 0; i < list.length; ++i) {
            s_balance[list[i]] = 2;
        }
    }

    //@notice removes members from DAO
    function removeMember(address _member) public onlyOwner {
        s_balance[_member] = 0;
        s_totalTokens -= MEMBER_TOKENS;
    }

    function removeVP(address _vp) public onlyOwner {
        s_balance[_vp] = 0;
        s_totalTokens -= VP_TOKENS;
    }

    // Democracy functions

    function impeach(address _newPresident) public onlyMember {
        if (
            s_impeachments[s_openImpeachments[_newPresident]].startTime +
                7 days <
            block.timestamp
        ) {
        if (
            s_impeachments[s_openImpeachments[_newPresident]].startTime +
                7 days <
            block.timestamp
        ) {
            delete s_openImpeachments[_newPresident];
        } else if (s_openImpeachments[_newPresident] != 0) {
            s_impeachments[s_openImpeachments[_newPresident]]
                .votes += s_balance[msg.sender];
        } else {
        } else if (s_openImpeachments[_newPresident] != 0) {
            s_impeachments[s_openImpeachments[_newPresident]]
                .votes += s_balance[msg.sender];
        } else {
            s_openImpeachments[_newPresident] = s_impeachments.length;
            s_impeachments.push(
                Impeachment(
                    _newPresident,
                    block.timestamp,
                    s_balance[msg.sender]
                )
            );
            s_impeachments.push(
                Impeachment(
                    _newPresident,
                    block.timestamp,
                    s_balance[msg.sender]
                )
            );
        }

        if (
            s_impeachments[s_openImpeachments[_newPresident]].votes >
            ((s_totalTokens / 4) * 3)
        ) {
        if (
            s_impeachments[s_openImpeachments[_newPresident]].votes >
            ((s_totalTokens / 4) * 3)
        ) {
            newPresident(_newPresident);
            delete s_openImpeachments[_newPresident];
        }
    }

    // Proposals and voting

    function addProposal(string calldata _proposal) public onlyMember {
    function addProposal(string calldata _proposal) public onlyMember {
        s_proposals.push(Proposal(_proposal, 0, 0));
        emit NewProposal(_proposal);
    }

    //@notice votes on a proposal
    function vote(uint _proposal, bool _vote) public onlyMember {
        if (s_votes[_proposal][msg.sender] == true) {
        if (s_votes[_proposal][msg.sender] == true) {
            revert AlreadyVoted();
        }


        // Adds vote
        if (_vote) {
            s_proposals[_proposal].votesYa =
                s_proposals[_proposal].votesYa +
                s_balance[msg.sender];
        } else {
            s_proposals[_proposal].votesNay =
                s_proposals[_proposal].votesNay +
                s_balance[msg.sender];
        if (_vote) {
            s_proposals[_proposal].votesYa =
                s_proposals[_proposal].votesYa +
                s_balance[msg.sender];
        } else {
            s_proposals[_proposal].votesNay =
                s_proposals[_proposal].votesNay +
                s_balance[msg.sender];
        }

        s_votes[_proposal][msg.sender] = true;


        // Checks if proposal passed
        if (s_proposals[_proposal].votesYa > s_totalTokens / 2) {
            emit ProposalPassed(s_proposals[_proposal].proposal);
        } else if (s_proposals[_proposal].votesNay > s_totalTokens / 2) {
        } else if (s_proposals[_proposal].votesNay > s_totalTokens / 2) {
            emit ProposalFailed(s_proposals[_proposal].proposal);
        }
    }

    // Meeting functions

    function newMeeting(string calldata topic) public onlyPresident {
        if (s_currentMeeting.open) {
        if (s_currentMeeting.open) {
            revert MeetingIsAlreadyOpen();
        }


        address[] memory attendees;
        s_currentMeeting = Meeting(block.timestamp, topic, attendees, true);
    }

    function checkIn() public {
        if (!s_currentMeeting.open) {
        if (!s_currentMeeting.open) {
            revert MeetingNotOpen();
        }


        // Parse through current meeting attendees to see if address has already checked in
        if (s_currentMeeting.attendees.length > 0) {
            for (uint i = 0; i < s_currentMeeting.attendees.length; i++) {
                if (s_currentMeeting.attendees[i] == msg.sender) {
        if (s_currentMeeting.attendees.length > 0) {
            for (uint i = 0; i < s_currentMeeting.attendees.length; i++) {
                if (s_currentMeeting.attendees[i] == msg.sender) {
                    revert AlreadyCheckedIn();
                }
            }
            s_currentMeeting.attendees[s_currentMeeting.attendees.length] = msg
                .sender;
        }

        if (s_balance[msg.sender] < 1) {
            s_notYetMembers[msg.sender] += 1;

            if (s_notYetMembers[msg.sender] >= MEETINGS_REQUIRED_TO_JOIN) {
                addMember(msg.sender);
                delete s_notYetMembers[msg.sender];
            }
        }

        s_currentMeeting.attendees.push(msg.sender);
    }

    function closeMeeting() public onlyPresident {
        s_currentMeeting.open = false;
        s_pastMeetings.push(s_currentMeeting);
    }

    //Getters

    function getPastMeetings() public view returns (Meeting[] memory) {
        return s_pastMeetings;
    }

    function getCurrentMeetingTopic() public view returns (string memory) {
        return s_currentMeeting.topic;
    }

    function getProposals() public view returns (Proposal[] memory) {
        return s_proposals;
    }

    function getBalance(address _address) public view onlyOwner returns (uint) {
        return s_balance[_address];
    }

    function getTokenHolder(address _holder) public view returns (bool) {
        if (s_balance[_holder] > 0) {
            return true;
        }
        return false;
    }
}
