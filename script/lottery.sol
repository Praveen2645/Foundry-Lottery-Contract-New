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

function pickWinner() external{
//check to see if enough time has passed
if((block.timestamp - s_lastTimeStamp)< i_interval){
revert();
}
s_lotteryState = LotteryState.CALCULATING;

//requesting the vrf random number 
  uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,//gas lane you can mention if you dont want to spent more or keyHash
            i_subscriptionId,//id that you funded the link
            REQUEST_CONFIRMATIONS,// block confirmations for random numbers
            i_callbackGasLimit, //max limit for gas
            NUM_WORDS//number of random nmbers
        );
}

//this function will return the random number
function fulfillRandomWords(
        uint256 requestId,
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
