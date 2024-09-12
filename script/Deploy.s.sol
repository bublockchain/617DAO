// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {DAO} from "../src/DAO.sol";
import {Faucet} from "../src/Faucet.sol";

contract Deploy is Script {
    DAO dao;
    Faucet faucet;

    function run() external {
        vm.startBroadcast();
        dao = new DAO();
        faucet = new Faucet(address(dao));
        dao.setFaucet(address(faucet));
        vm.stopBroadcast();
    }
}