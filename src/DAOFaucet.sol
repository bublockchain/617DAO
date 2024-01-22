pragma solidity ^0.8.20;

import {BUBDAO} from "./617DAO.sol";

contract DAOFaucet {
    event Deposit(address indexed sender, uint256 amount);
    event Funding(address indexed sentTo, bytes data);
    event DrainedFunds();

    address private s_owner;
    BUBDAO s_dao;
    Request[] s_requests;
    uint256[] s_openRequestIDs;
    uint256 constant fundAmount = 1 ether;

    error Unauthorized_OnlyOwner();
    error OnlyDAOMembersCanRequestFunds();
    error AlreadyCompletedRequest();
    error FailedTransaction(bytes data);
    error NoRequestFound();

    modifier onlyOwner() {
        if (msg.sender != s_owner) {
            revert Unauthorized_OnlyOwner();
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
        if (s_requests[_requestID].requestID == 0) {
            revert NoRequestFound();
        }

        if (s_requests[_requestID].completed) {
            revert AlreadyCompletedRequest();
        }
        //Move request to closed funding requests
        s_requests[_requestID].completed = true;
        //Remove entry from open requests
        bool found = false;
        for (uint i; i < s_openRequestIDs.length - 1; ++i) {
            if (!found && s_openRequestIDs[i] == _requestID) {
                found = true;
            }
            if (found) {
                s_openRequestIDs[i] = s_openRequestIDs[i + 1];
            }
        }
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
    function sendFunds(address _to) external onlyOwner {
        (bool success, bytes memory data) = _to.call{value: fundAmount}("");

        if (!success) {
            revert FailedTransaction(data);
        }

        emit Funding(_to, data);
    }

    //Transfer out all funds
    function drainContract() external onlyOwner {
        (bool success, bytes memory data) = s_owner.call{
            value: address(this).balance
        }("");

        if (!success) {
            revert FailedTransaction(data);
        }

        emit DrainedFunds();
    }

    //Get total funds
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    //Get active requests
    function getActiveRequests() external view returns (uint256[] memory) {
        return s_openRequestIDs;
    }
}
