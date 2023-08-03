// SPDX-License-Identifier: MIT

import {Script} from "../lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
pragma solidity ^0.8.19;

contract HelperConfig is Script{

    struct NetworkConfig{
     uint256 enteranceFee;
     uint256 interval;
     address vrfCoordinator;
     bytes32 gasLane;
     uint64 subscriptionId;
     uint32 callbackGasLimit;
    }

    NetworkConfig public activeNetworkConfig;

    constructor(){
        if (block.chainid == 11155111){
            activeNetworkConfig = getSepoliaEthConfig();
        }else{
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }
// for sepolia test-net
function getSepoliaEthConfig() public pure returns (NetworkConfig memory){
return NetworkConfig({
    enteranceFee: 0.01 ether,
    interval: 30,
    vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
    gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
    subscriptionId: 0,
    callbackGasLimit: 500000
});
}

// for local-net
function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory){

    if(activeNetworkConfig.vrfCoordinator != address(0)){
        return activeNetworkConfig;
    }
    //constructor for the VFRcoordinator
    uint96 baseFee = 0.25 ether; // 0.25 LINK
    uint96 gasPriceLink = 1e9; //1 gwei

    //to deploy on any network
    vm.startBroadcast();
    VRFCoordinatorV2Mock vrfCoordinatorMOck = new VRFCoordinatorV2Mock(
        baseFee, 
        gasPriceLink
        );
    vm.stopBroadcast();
    return NetworkConfig({
        enteranceFee: 0.01 ether,
    interval: 30,
    vrfCoordinator: address(vrfCoordinatorMOck),
    gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
    subscriptionId: 0, //script will add this
    callbackGasLimit: 500000
    });

}
}