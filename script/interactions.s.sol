// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script{
    function createSubscriptionUsingConfig() public returns (uint64){
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , , ) = helperConfig.activeNetworkConfig ();
        return createSubscription (vrfCoordinator);
    }
//creating the subscription by programitacly
    function createSubscription(
        address vrfCoordinator
        ) public returns(uint64){
            console.log("Creating subscription on ChainId:", block.chainid);
        vm.startBroadcast();
   uint64 subId =  VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your subs Id is: ", subId);
        console.log("Please update subscriptionId in HelpeerConfig.s.sol");
        return subId; 
    }

    function run() external returns (uint64){
        return createSubscriptionUsingConfig();
    }
}
//funding  
//to fund a subscription  we need id,VRF address,Link Add.
contract FundSubscription is Script{
    uint96 public constant FUND_AMOUNT = 3 ether;

function fundSubscriptionUsingConfig() public {
HelperConfig helperConfig = new HelperConfig();
        ( 
            , 
            , 
            address vrfCoordinator,
            ,
            uint64 subId,
            ,
            address link
            ) = helperConfig.activeNetworkConfig ();
            fundSubscription(vrfCoordinator, subId, link);
}

function fundSubscription(address vrfCoordinator,uint64 subId,address link) public{
console.log("Funding subscription: ",subId);
console.log("Using vrfCoordinator:", vrfCoordinator);
console.log("On ChainID:", block.chainid);
if (block.chainid == 31337){
    vm.startBroadcast();
    VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(
        subId,
        FUND_AMOUNT
    );
    vm.stopBroadcast();
} else {
    vm.startBroadcast();
    LinkToken(link).transferAndCall(
        vrfCoordinator,
        FUND_AMOUNT,
        abi.encode(subId)
    );
    vm.stopBroadcast();
}

}

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

//adding consumer
contract AddConsumer is Script{
    function addConsumer(
        address lottery,
        address vrfCoordinator,
        uint64 subId
    ) public {
        console.log("Adding consumer Contract:",lottery);
        console.log("Using vrfCoordinator:",vrfCoordinator);
        console.log("On ChainId:", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId,lottery);
        vm.stopBroadcast();
    }

function addConsumerUsingConfig(address lottery) public{
    HelperConfig helperConfig = new HelperConfig();
     ( ,  , address vrfCoordinator, ,uint64 subId,,) = helperConfig.activeNetworkConfig ();
     addConsumer(lottery,vrfCoordinator, subId);
}

    function run() external {
        address lottery = DevOpsTools.get_most_recent_deployment(
            "Lottery",
            block.chainid
        );
        addConsumerUsingConfig(lottery);
    }
}

