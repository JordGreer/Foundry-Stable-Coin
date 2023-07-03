//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {Script, console} from "forge-std/Script.sol";

contract DeployDSC is Script {
    DecentralizedStableCoin dsc;

    function run() public returns (DecentralizedStableCoin) {
        vm.startBroadcast();
        dsc = new DecentralizedStableCoin();
        vm.stopBroadcast();

        console.log(
            "Deployed DecentralizedStableCoin at address: %s",
            address(dsc)
        );

        return dsc;
    }
}
