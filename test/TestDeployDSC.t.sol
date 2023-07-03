//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";

contract TestDeployDSC is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;

    function setUp() public {
        deployer = new DeployDSC();
        dsc = deployer.run();
        console.log(
            "Deployed DecentralizedStableCoin at address: %s",
            address(dsc)
        );
    }
}
