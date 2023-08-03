// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {Lottery} from "../src/lottery.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription} from "./interactions.s.sol";


contract DeployLottery is Script{

function run() external returns (Lottery,HelperConfig){
    HelperConfig helperConfig = new HelperConfig(); //creating instance
    (
          
     uint256 enteranceFee, 
     uint256 interval,
     address vrfCoordinator,
     bytes32 gasLane,
     uint64 subscriptionId,
     uint32 callbackGasLimit
    ) = helperConfig.activeNetworkConfig ();   

    if (subscriptionId == 0){
        //creating the subscription id
        CreateSubscription createSubscription = new CreateSubscription();
        subscriptionId = createSubscription.createSubscription(vrfCoordinator);
    }

    vm.startBroadcast();
    Lottery lottery = new Lottery(
        enteranceFee,
        interval,
        vrfCoordinator,
        gasLane,
        subscriptionId,
        callbackGasLimit
    );
    vm.stopBroadcast();
    return (lottery, helperConfig);
}
}