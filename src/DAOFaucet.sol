pragma solidity ^0.8.20;

import {BUBDAO} from "./617DAO.sol";

contract DAOFaucet {
    event Deposit(address sender, uint256 amount);
    event Funding(address sentTo, bytes data);

    address private s_owner;
    BUBDAO s_dao;
    Request[] s_requests;
    uint256[] s_openRequestIDs;
    uint256 constant fundAmount = 1 ether;

    error Unauthorized_OnlyOwner();
    error OnlyDAOMembersCanRequestFunds();
    error AlreadyCompletedRequest();
    error FailedTransaction(bytes data);

    modifier onlyOwner() {
        if (msg.sender != s_owner) {
            revert Unauthorized_OnlyOwner();
        }
        _;
    }

    modifier openRequest(uint256 _requestID) {
        if (s_requests[_requestID].completed) {
            revert AlreadyCompletedRequest();
        }
        _;
    }

    constructor(address _dao) {
        s_owner = msg.sender;
        s_dao = BUBDAO(_dao);
    }

    struct Request {
        address userAddress;
        string name;
        uint8 graduationYear;
        uint256 requestID;
        bool completed;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    //Request Funds
    function requestFunds(string calldata _name, uint8 _gradYear) public {
        if (!(s_dao.getTokenHolder(msg.sender))) {
            revert OnlyDAOMembersCanRequestFunds();
        }

        s_requests[s_requests.length] = Request(
            msg.sender,
            _name,
            _gradYear,
            s_requests.length,
            false
        );
        s_openRequestIDs[s_openRequestIDs.length] = s_requests.length - 1;
    }

    //Approve Requests
    function approveRequest(uint256 _requestID) external onlyOwner {
        //Move request to closed funding requests
        s_requests[_requestID].completed = true;
        //Remove entry from open requests
        //Send Transaction
        (bool success, bytes memory data) = s_requests[_requestID]
            .userAddress
            .call{value: fundAmount}("");
        if (!success) {
            revert FailedTransaction(data);
        }

        emit Funding(s_requests[_requestID].userAddress, data);
    }
    //Send Initial funds
    //Transfer out all funds
    //Get total funds
    //Get active requests
}
