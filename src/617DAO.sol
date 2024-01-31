// SPDX-License-Identifier: CC-BY-1.0
pragma solidity ^0.8.20;

//@title The Boston University Blockchain Club DAO
//@author Wes Jorgensen, @Wezabis on twtr
//@notice This contract is a simple DAO for the Boston University Blockchain Club

//Add an interface for the DAO

contract BUBDAO {
    // Set to BUB Wallet Address
    address public s_owner;
    address public s_president;

    // Token balances and total tokens
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
    error ElectionIsNotOpen();

    // Structs
    struct Proposal {
        string proposal;
        uint votesYay;
        uint votesNay;
    }

    struct Meeting {
        uint date;
        string topic;
        address[] attendees;
        bool open;
    }

    struct Impeachment {
        uint256 startTime;
        uint8 votes;
    }

    // State variables
    mapping(address => uint) private s_notYetMembers;
    mapping(uint => mapping(address => bool)) private s_votes;
    Proposal[] public s_proposals;
    Meeting private s_currentMeeting;
    Meeting[] private s_pastMeetings;
    Impeachment currentImpeachment = Impeachment(0, 0);
    mapping(uint256 => mapping(address => bool)) impeachmentVotes;
    uint256 impeachmentVersion = 0;
    uint256 impeachmentDuration = 7 days;
    bool public isElectionOpen = false;
    address[] candidates;
    mapping(uint256 => mapping(address => bool)) isCandidate;
    uint256 presidentialElectionVersion = 0;
    mapping(uint256 => mapping(address => uint256)) presidentialElectionVotes;
    uint256 electionOpenDate = 0;
    uint256 electionPeriod = 7 days;

    // Events
    event NewProposal(string proposal);
    event ProposalPassed(string proposal);
    event ProposalFailed(string proposal);
    event newImpeachmentAttempt(uint256 startTime, address startedBy);
    event ImpeachmentFailed(uint256 numberOfImpeachmentAttempts);
    event ImpeachmentSuccessful_ElectionOpen();
    event NewPresident(address newPresident, uint256 votes);
    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != s_owner) {
            revert Unauthorized_Only_Owner();
        }
        _;
    }

    modifier onlyMember() {
        if (s_balance[msg.sender] == 0) {
            revert Unauthorized_Only_Member();
        }
        _;
    }

    modifier onlyVP() {
        if (s_balance[msg.sender] < VP_TOKENS) {
            revert Unauthorized_Only_VP();
        }
        _;
    }

    modifier onlyPresident() {
        if (msg.sender != s_president) {
            revert Unauthorized_Only_President();
        }
        _;
    }

    //@notice Constructor sets the owner and president of the DAO
    constructor(address _president, address[] memory _members) {
        s_owner = msg.sender;
        newPresidentInternal(_president);
        airdrop(_members);
    }

    // All adding and removing members functions

    //@notice adds members to DAO
    function addMember(address _member) public onlyOwner {
        if (s_balance[_member] != 0) {
            revert AlreadyMember();
        }
        s_balance[_member] = MEMBER_TOKENS;
        s_totalTokens += MEMBER_TOKENS;
    }

    //@notice adds VP to DAO
    function addVP(address _vp) public onlyOwner {
        s_balance[_vp] = VP_TOKENS;
        s_totalTokens += VP_TOKENS;
    }

    //@notice adds President to DAO and removes old president
    function newPresident(address _president) public onlyPresident {
        s_balance[_president] = PRESIDENT_TOKENS;
        s_balance[s_president] = 0;
        s_president = _president;
        emit NewPresident(_president, 0);
    }

    function newPresidentInternal(address _president) internal {
        s_balance[_president] = PRESIDENT_TOKENS;
        s_balance[s_president] = 0;
        s_president = _president;
    }

    //@notice airdrops governance tokens to a list of new members
    function airdrop(address[] memory list) public onlyOwner {
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

    //Need to rework this segment
    function impeach() public onlyMember {
        if (impeachmentVotes[impeachmentVersion][msg.sender]) {
            revert AlreadyVoted();
        }

        if (currentImpeachment.startTime == 0) {
            currentImpeachment = Impeachment(block.number, s_balance[msg.sender]);
            ++impeachmentVersion;
            impeachmentVotes[impeachmentVersion][msg.sender] = true;
            emit newImpeachmentAttempt(block.number, msg.sender);
            return;
        }

        //end clause
        if ((currentImpeachment.startTime + impeachmentDuration) < block.timestamp) {
            currentImpeachment = Impeachment(0, 0);
            emit ImpeachmentFailed(impeachmentVersion);
            return;
        }

        //vote
        currentImpeachment.votes += s_balance[msg.sender];
        impeachmentVotes[impeachmentVersion][msg.sender] = true;

        if (currentImpeachment.votes * 4 >= s_totalTokens * 3) {
            openElection();
            currentImpeachment = Impeachment(0, 0);
            emit ImpeachmentSuccessful_ElectionOpen();
            return;
        }
    }

    function getCurrentImpeachment() external view returns(uint){
        return currentImpeachment.startTime + impeachmentDuration;
    }

    function openElection() internal {
        isElectionOpen = true;
        delete candidates;
        ++presidentialElectionVersion;
    }

    function voteInElection(address _newPresident) public onlyMember {
        if (!isElectionOpen) {
            revert ElectionIsNotOpen();
        }

        if (electionOpenDate + electionPeriod < block.number) {
            closeElection();
        }

        ++presidentialElectionVotes[presidentialElectionVersion][_newPresident];

        //Add candidate to array if not in
        if (!(isCandidate[presidentialElectionVersion][_newPresident])) {
            candidates.push(_newPresident);
        }

        //see if end of election
    }

    function closeElection() public {
        isElectionOpen = false;
        address mostVotes = address(0);
        for (uint i; i < candidates.length; ++i) {
            if (
                presidentialElectionVotes[presidentialElectionVersion][
                    candidates[i]
                ] >
                presidentialElectionVotes[presidentialElectionVersion][
                    mostVotes
                ]
            ) {
                mostVotes = candidates[i];
            }
        }

        newPresidentInternal(mostVotes);
        emit NewPresident(
            mostVotes,
            presidentialElectionVotes[presidentialElectionVersion][mostVotes]
        );
    }

    // Proposals and voting

    function addProposal(string calldata _proposal) public onlyMember {
        s_proposals.push(Proposal(_proposal, 0, 0));
        emit NewProposal(_proposal);
    }

    //@notice votes on a proposal
    function vote(uint _proposal, bool _vote) public onlyMember {
        if (s_votes[_proposal][msg.sender] == true) {
            revert AlreadyVoted();
        }

        // Adds vote
        if (_vote) {
            s_proposals[_proposal].votesYay =
                s_proposals[_proposal].votesYay +
                s_balance[msg.sender];
        } else {
            s_proposals[_proposal].votesNay =
                s_proposals[_proposal].votesNay +
                s_balance[msg.sender];
        }

        s_votes[_proposal][msg.sender] = true;

        // Checks if proposal passed
        if (s_proposals[_proposal].votesYay * 2 >= s_totalTokens) {
            emit ProposalPassed(s_proposals[_proposal].proposal);
        } else if (s_proposals[_proposal].votesNay * 2 > s_totalTokens) {
            emit ProposalFailed(s_proposals[_proposal].proposal);
        }
    }

    // Meeting functions

    function newMeeting(string calldata topic) public onlyPresident {
        if (s_currentMeeting.open) {
            revert MeetingIsAlreadyOpen();
        }

        address[] memory attendees;
        s_currentMeeting = Meeting(block.timestamp, topic, attendees, true);
    }

    function checkIn() public {
        if (!s_currentMeeting.open) {
            revert MeetingNotOpen();
        }

        // Parse through current meeting attendees to see if address has already checked in
        if (s_currentMeeting.attendees.length > 0) {
            for (uint i; i < s_currentMeeting.attendees.length; i++) {
                if (s_currentMeeting.attendees[i] == msg.sender) {
                    revert AlreadyCheckedIn();
                }
            }
        }

        s_currentMeeting.attendees.push(msg.sender);

        //If they have checked in
        if (s_balance[msg.sender] < 1) {
            s_notYetMembers[msg.sender] += 1;

            if (s_notYetMembers[msg.sender] >= MEETINGS_REQUIRED_TO_JOIN) {
                s_balance[msg.sender] = MEMBER_TOKENS;
                s_totalTokens += MEMBER_TOKENS;
                s_notYetMembers[msg.sender] = 0;
            }
        }
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
