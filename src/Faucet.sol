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

import {DAO} from "./DAO.sol";

contract Faucet {
    DAO private immutable dao;
    mapping(address => uint256) private s_lastRequest;
    uint256 private s_fundingAmount = 1e16;

    uint256 constant COOLDOWN_PERIOD = 3 weeks;

    error OnlyDAO();
    error OnlyPresident();
    error OnlyMember();
    error TransactionFailed(bytes data);
    error InsufficientBankBalance();
    error TooSoonSinceLastRequest();

    modifier onlyPresident() {
        if(!dao.isPresident(msg.sender)){
            revert OnlyPresident();
        }
        _;
    }

    modifier balanceCheck() {
        if(address(this).balance < s_fundingAmount){
            revert InsufficientBankBalance();
        }
        _;
    }

    constructor(address _dao){
        dao = DAO(_dao);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @notice Make a funding request to be able to use DAO functions
     * @dev Only able to be called 3 weeks after last request
     * @dev Only callable by members
     */
    function makeFundingRequest() public balanceCheck {
        if(!dao.isMember(msg.sender)){
            revert OnlyMember();
        }

        if((s_lastRequest[msg.sender] + COOLDOWN_PERIOD) > block.number){
            revert TooSoonSinceLastRequest();
        }

        (bool success, bytes memory data) = payable(msg.sender).call{value: s_fundingAmount}("");
        s_lastRequest[msg.sender] = block.number;

        if(!success){
            revert TransactionFailed(data);
        }
    }

    /**
     * @notice Function for DAO to call when a new member is added and doesn't have funds
     * @dev Only callable by DAO
     * @param _toFund Address to send funds to
     */
    function initalFundingRequestFromDAO(address _toFund) external balanceCheck {
        if(msg.sender != address(dao)){
            revert OnlyDAO();
        }

        (bool success, bytes memory data) = payable(_toFund).call{value: s_fundingAmount}("");
        s_lastRequest[_toFund] = block.number;

        if(!success){
            revert TransactionFailed(data);
        }
    }

    /**
     * @notice Changes default funding amount
     * @dev Only callable by president
     * @param _newAmount New amount for funding requests
     */
    function changeFundingAmount(uint256 _newAmount) external onlyPresident {
        s_fundingAmount = _newAmount;
    }

    /**
     * @notice Withdraws all funds from contract
     * @dev Only callable by president
     */
    function withdrawFunds() external onlyPresident {
        (bool success, bytes memory data) = payable(msg.sender).call{value: address(this).balance}("");

        if(!success){
            revert TransactionFailed(data);
        }
    }

    /**
     * @notice returns the default amount members get
     */
    function getDeafultFundingAmount() external view returns (uint256) {
        return s_fundingAmount;
    }


}