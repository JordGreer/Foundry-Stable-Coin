//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {DSCEngine} from "src/DSCEngine.sol";

contract TestDeployDSC is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dscEngine;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dscEngine) = deployer.run();
    }

    function testDeployDSC() public {
        //Assert the deploy worked, DSC owner should be the DSC Engine
        assertEq(address(dsc.owner()), address(dscEngine));
        //Assert the DSC Engine has the correct DSC address
        assertEq(dscEngine.getDscAddress(), address(dsc));
    }
}
