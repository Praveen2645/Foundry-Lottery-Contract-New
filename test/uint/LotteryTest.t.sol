// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployLottery} from "../../script/DeployLottery.s.sol";
import {Lottery} from "../../src/lottery.sol";
import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract LotteryTest is Test {
    /* Events*/
    event EnteredLottery(address indexed player);

    Lottery lottery;
    HelperConfig helperConfig;

     uint256 enteranceFee; 
     uint256 interval;
     address vrfCoordinator;
     bytes32 gasLane;
     uint64 subscriptionId;
     uint32 callbackGasLimit;
     address link;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

 function setUp() external {
    DeployLottery deployer = new DeployLottery(); //creating instance
    (lottery, helperConfig)  = deployer.run();
    (
      enteranceFee, 
      interval,
      vrfCoordinator,
      gasLane,
      subscriptionId,
      callbackGasLimit,
       link
    ) = helperConfig.activeNetworkConfig ();
    vm.deal(PLAYER,STARTING_USER_BALANCE); //giving an address some money
    
 }
 //testCases
//1. checking or the lottry is open ?
 function testLotteryInitilizesInOpenState() public view {
    assert(lottery.getLotteryState() == Lottery.LotteryState.OPEN);
 }
//////////////////
//enter Lottery//
/////////////////

function testLotteryRevertsWhenYouDontPayEnough() public {
    //Arrange
    vm.prank(PLAYER); //pretending to be a player
    //Act/Assert
    vm.expectRevert(Lottery.Lottery__NotEnoughEthSent.selector); //expecting error
    lottery.enterLottery();

}
function testLotteryRecordsPlayersWhenTheyEnter() public{ //s_players array is updated when player joins
 vm.prank(PLAYER); 
 lottery.enterLottery {value: enteranceFee}();
 address playerRecorded = lottery.getPlayer(0);
 assert((playerRecorded == PLAYER));

}
//for emitting the event on enter the lottery
function testEmitsEventOnEntrance() public{
    vm.prank(PLAYER);
    vm.expectEmit(true,false,false,false,address(lottery));
    emit EnteredLottery(PLAYER);
    lottery.enterLottery{value: enteranceFee}();
}

function testCantEnterWhenRaffleIsCalculating() public {
    vm.prank(PLAYER);
    lottery.enterLottery{value: enteranceFee}();
//vm.warp- sets block.timestamp
//vm.roll- sets the blockNumber
    vm.warp(block.timestamp + interval +1);
    vm.roll(block.number + 1);
    lottery.performUpkeep("");

    vm.expectRevert(Lottery.Lottery__LotteryNotOpen.selector);
    vm.prank(PLAYER);
    lottery.enterLottery{value: enteranceFee}();
}

}