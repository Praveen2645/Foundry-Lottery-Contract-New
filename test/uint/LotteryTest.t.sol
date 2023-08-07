// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployLottery} from "../../script/DeployLottery.s.sol";
import {Lottery} from "../../src/lottery.sol";
import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2Mock} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

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
       link,
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
///////////////////////////
///checkupkeeps //
////////////////////////
function testCheckUpkeepReturnFalseIfItHasNobalance() public {
    //arrange
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);

    //Act
    (bool upkeepNeeded, ) = lottery.checkUpkeep("");

    //assert
    assert(!upkeepNeeded);
}
//return false if raffle isnt open

function testCheckUpkeepReturnsFalseIfLotteryNotOpen() public{
//arrange
vm.prank(PLAYER);// pranking to be a player
lottery.enterLottery{value: enteranceFee}();// paying entry fee
vm.warp(block.timestamp + interval + 1);
vm.roll(block.number + 1);
lottery.performUpkeep("");//in the calculting state

//Act
(bool upkeepNeeded, ) = lottery.checkUpkeep("");

//assert
assert(upkeepNeeded == false);
}
////////////////////////////
/// performUpkeeps  //
////////////////////////////
function testPerformUpkeepCanOnlyRunIfCheckUpkeepsIsTrue() public{
    //arrange
    vm.prank(PLAYER);
    lottery.enterLottery{value:enteranceFee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);

    //act/assert
    lottery.performUpkeep("");

}
function testPerformUpkeepCanOnlyRevertsIfCheckUpkeepsIsFalse() public{
//arrange
uint256 currentBalance = 0;
uint256 numPlayers = 0;
uint256 lotteryState = 0;

//act/assert
vm.expectRevert(
    abi.encodeWithSelector(
        Lottery.Lottery__UpkeepNotNeeded.selector,
        currentBalance,
        numPlayers,
        lotteryState
    )
);
lottery.performUpkeep("");

}
modifier lotteryEnteredAndTimePassed() {
     vm.prank(PLAYER);
    lottery.enterLottery{value:enteranceFee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    _;
}

//what if i need to test using the output of an event?
function testPerformUpKeepUpdateLotteryStateAndEmitsRequestId()
 public 
lotteryEnteredAndTimePassed()
{
 //Act
 vm.recordLogs();//this can save all the logs outputs
 lottery.performUpkeep(""); //this will emit the reuestId
 Vm.Log[] memory entries = vm.getRecordedLogs(); //we ll get all the recent events emited
//geting out the requestId from this list of events
bytes32 requestId = entries[1].topics[1];

Lottery.LotteryState rState = lottery.getLotteryState();

assert(uint256(requestId) > 0);
assert(uint256(rState) == 1);
}

///////////////////////
// fulfilRandomWords //
///////////////////////

modifier skipFork(){
    if(block.chainid != 31337){
        return;
    }
    _;
}

//we are pretending to be chainlinkVRF coz on local there is no chainVRF
//NOTE: wont work on the real tesnet, just for testing
function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
    uint256 randomRequestId
) 
public 
lotteryEnteredAndTimePassed()
{
//arrange
vm.expectRevert("nonexistent request");//noRequestId we get nonexistent request
VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords( //pretending to be the VRFCoordinator,since we using the mock,the fullfilRandomWords can be call by anybody
    randomRequestId,
    address(lottery)
);
//in output you notice run: 256 - which is done by the foundry - also known as fuzz
}
function testFulfilRandomWordsPicksAWinnerResetsAndSendMoney() 
public
lotteryEnteredAndTimePassed
{
//Arrange
uint256 additionalEntrance = 5; //in modifier we can only get one entrance, here we can add 5 entrance
uint256 startingIndex = 1;
for(uint256 i = startingIndex; i< startingIndex+ additionalEntrance; i++){
//creating player
address player = address(uint160(i)); //now each player have the diff add
hoax(player, STARTING_USER_BALANCE);// player pretending to have 1 ether
lottery.enterLottery{value: enteranceFee}();//entering Lottrey
}

uint256 prize  = enteranceFee * (additionalEntrance + 1);

vm.recordLogs();
lottery.performUpkeep("");
Vm.Log[] memory entries = vm.getRecordedLogs();
bytes32 requestId = entries[1].topics[1];

uint256 previousTimeStamp = lottery.getLastTimeStamp();

//pretend to be the ChainLinkVRF to get a random number and pick winner
VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(  
    uint256(requestId),//we typecast as a uint256 as above id is in byttes32
    address(lottery)
);
//Asserts
assert(uint256(lottery.getLotteryState()) == 0 );
assert(lottery.getRecentWinner() != address(0));
assert(lottery.getLengthOfPlayers() == 0);
assert(previousTimeStamp < lottery.getLastTimeStamp());
assert(lottery.getRecentWinner().balance == STARTING_USER_BALANCE + prize - enteranceFee);
    
}
}