//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {Script, console} from "forge-std/Script.sol";
import {Helperconfig} from "./HelperConfig.s.sol";

contract DeployDSC is Script {
    address[] public tokensAddresses;
    address[] public priceFeedAddresses;

    function run() public returns (DecentralizedStableCoin, DSCEngine) {
        Helperconfig config = new Helperconfig();

        (
            address wethUsdPriceFeed,
            address wbtcUsdPriceFeed,
            address weth,
            address wbtc,
            uint256 deployerKey
        ) = config.activeNetworkConfig();

        tokensAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        vm.startBroadcast(deployerKey);
        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        DSCEngine dscEngine = new DSCEngine(
            tokensAddresses,
            priceFeedAddresses,
            address(dsc)
        );
        dsc.transferOwnership(address(dscEngine));
        vm.stopBroadcast();
        return (dsc, dscEngine);
    }
}
