// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {VRFCoordinatorV2Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/VRFConsumerBaseV2.sol";
/**
 * @title  lottery contract
 * @author pp
 * @notice  simple lottery contract
 * @dev implement chainLink VRFv2 
 */

contract Lottery is VRFConsumerBaseV2 {
    error Lottery__NotEnoughEthSent();
    error Lottery__TransferFailed();
    error Lottery__LotteryNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance, 
        uint256 numPlayers, 
        uint256 lotteryState
        );

    /* Type declaration*/
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    /**State Variable */
    uint16 private constant REQUEST_CONFIRMATIONS = 3; //block confirmations for random numbers
    uint32 private constant NUM_WORDS = 1; //number of random number we want

    uint256 private immutable i_enteranceFee;
    //@dev duration of the lottery in seconds
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    LotteryState private s_lotteryState;
    /**Events */
    event EnteredLottery(address indexed player);
    event PickedWinner(address indexed winner);

    constructor(
        
     uint256 enteranceFee,
     uint256 interval,
     address vrfCoordinator,
     bytes32 gasLane,
     uint64 subscriptionId,
     uint32 callbackGasLimit
     ) VRFConsumerBaseV2(vrfCoordinator){
        i_enteranceFee = enteranceFee;
        i_interval=interval;
        i_gasLane= gasLane;
        i_vrfCoordinator = VRFCoordinatorV2Interface (vrfCoordinator);
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
       
    }

function enterLottery() external payable{
   // require(msg.value >= i_enteranceFee);
   if (msg.value < i_enteranceFee){
    revert Lottery__NotEnoughEthSent(); 
   }
   if (s_lotteryState != LotteryState.OPEN){ // only enter to lotteryb if its open
    revert Lottery__LotteryNotOpen();
   }
   s_players.push(payable(msg.sender));
   emit EnteredLottery(msg.sender);
}

/**
 * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.

 */
//function performed when the winner is picked
function checkUpkeep(bytes memory /*chaeckData*/) public view returns(bool upkeepNeeded, bytes memory /*performData*/){
bool timeHasPassed = (block.timestamp - s_lastTimeStamp)>= i_interval;
bool isOpen = LotteryState.OPEN == s_lotteryState;
bool hasBalance = address(this).balance>0;
bool hasPlayers = s_players.length > 0;
upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
return (upkeepNeeded,"0x0");
//if checkUpkeep is true then it will call the upkeep function
}

function performUpkeep(bytes calldata /* performData*/) external{
(bool upkeepNeeded, ) = checkUpkeep("");
if (!upkeepNeeded){
    revert Raffle__UpkeepNotNeeded(  
        address(this).balance,
    s_players.length,
    uint256(s_lotteryState)
    );
}
// ckeck to see if enough time has passed
s_lotteryState = LotteryState.CALCULATING;

//requesting the vrf random number 
   i_vrfCoordinator.requestRandomWords(
            i_gasLane,//gas lane you can mention if you dont want to spent more or keyHash
            i_subscriptionId,//id that you funded the link
            REQUEST_CONFIRMATIONS,// block confirmations for random numbers
            i_callbackGasLimit, //max limit for gas
            NUM_WORDS//number of random nmbers
        );
}

//this function will return the random number
function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        //checks
        //Effects(on our own contract)

      //wanna pick the random winner from the s_players  
        uint256 indexOfWinner = randomWords[0] % s_players.length; //getting the index of the winner
        address payable winner = s_players[indexOfWinner];// assigning the winner
        s_recentWinner = winner;
        s_lotteryState = LotteryState.OPEN;

        s_players = new address payable[](0); // resetting the array
        s_lastTimeStamp = block.timestamp; // resetting the new-time
        emit PickedWinner(winner);
    //Interactions(other contracts)
        (bool success,) = winner.call{value: address(this).balance}("");//transfering balance
        if(!success){
            revert Lottery__TransferFailed();
        }
    }

/**getter functions */
function getEntranceFee() external view returns(uint256){
    return i_enteranceFee;  
}

}
//checks- if else, require
//effect- effects of the contract,push variable declarations...
//interactions- interaction wtih the other cotracts - to avoid reentrancy attacks