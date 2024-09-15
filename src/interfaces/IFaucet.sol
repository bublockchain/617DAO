// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFaucet {
    error OnlyDAO();
    error OnlyPresident();
    error OnlyMember();
    error TransactionFailed(bytes data);
    error InsufficientBankBalance();
    error TooSoonSinceLastRequest();

    receive() external payable;

    fallback() external payable;

    /**
     * @notice Make a funding request to be able to use DAO functions
     * @dev Only able to be called 3 weeks after last request
     * @dev Only callable by members
     */
    function makeFundingRequest() external;

    /**
     * @notice Function for DAO to call when a new member is added and doesn't have funds
     * @dev Only callable by DAO
     * @param _toFund Address to send funds to
     */
    function initalFundingRequestFromDAO(address _toFund) external;

    /**
     * @notice Changes default funding amount
     * @dev Only callable by president
     * @param _newAmount New amount for funding requests
     */
    function changeFundingAmount(uint256 _newAmount) external;

    /**
     * @notice Withdraws all funds from contract
     * @dev Only callable by president
     */
    function withdrawFunds() external;

    /**
     * @notice returns the default amount members get
     */
    function getDeafultFundingAmount() external view returns (uint256);
}