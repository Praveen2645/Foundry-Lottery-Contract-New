// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title  lottery contract
 * @author Praveen Patawkar
 * @notice  simple lottery contract
 * @dev implement chainLink VRFv2 
 */

contract Lottery{
    error Lottery__NotEnoughEthSent();

    uint256 private immutable i_enteranceFee;
    //@dev duration of the lottery in seconds
    uint256 private immutable i_interval;
    address payable[] private s_players;
    /**Events */
    event EnteredLottery(address indexed player);

    constructor(uint256 enteranceFee, uint256 interval){
        i_enteranceFee = enteranceFee;
        i_interval=interval;
    }


function enterLottery() external payable{
   // require(msg.value >= i_enteranceFee);
   if (msg.value < i_enteranceFee){
    revert Lottery__NotEnoughEthSent(); 
   }
   s_players.push(payable(msg.sender));
   emit EnteredLottery(msg.sender);
}

function pickWinner() public{

}

/**getter functions */
function getEntranceFee() external view returns(uint256){
    return i_enteranceFee;
}
}
