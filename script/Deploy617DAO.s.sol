pragma solidity 0.8.20;

import {Script} from "../lib/forge-std/src/Script.sol";
import {BUBDAO} from "../src/617DAO.sol";
import {DAOFaucet} from "../src/DAOFaucet.sol";

contract Deploy617DAO is Script {
    function run(
        address president,
        address[] memory members
    ) public returns (BUBDAO) {
        vm.startBroadcast();
        BUBDAO dao = new BUBDAO(president, members);
        vm.stopBroadcast();
        return dao;
    }
}
