// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

struct Pick {
  uint256 line;
  string name;
}

struct SingleBet {
  address payable bettorAddress;
  uint256 line;
  uint256 amount;
}

error Bet__SendMoreToBet(uint256 amount);
error Bet__SendLessToBet(uint256 amount);
error Bet__ContracNotInitialized();


contract Bet {
  uint256 public constant MINIMUM_BET = 0.005 ether;
  // uint8 public constant FEE_PERCENTAGE = uint8(1) / uint8(10);

  uint256 public immutable i_startUpdating;
  uint256 public immutable i_interval;
  bool public  i_initizialized = false;
  Pick public i_favorite;
  Pick public i_dog;
  


  uint256 private s_lastTimeStamp;
  SingleBet[] private s_favoritters;
  SingleBet[] private s_doggers;

  event BetEnter(address indexed bettor);

  constructor(
    Pick memory favorite,
    Pick memory dog,
    uint256 startUpdating,
    uint256 interval
  ) {
    i_favorite = favorite;
    i_dog = dog;
    i_startUpdating = startUpdating;
    i_interval = interval;
    s_lastTimeStamp = block.timestamp;
  }

  function bet(bool wantsFavorite) external payable {

    if (this.i_initizialized) {
      revert Bet__ContracNotInitialized();
    }
    
    if (msg.value < MINIMUM_BET) {
      revert Bet__SendMoreToBet(this.MINIMUM_BET);
    }
    uint256 max = (this.getBalacnce()*100)/(wantsFavorite ? i_favorite.line : i_dog.line);
    if (msg.value > max) {
        revert Bet__SendLessToBet(max);
    }

    uint256 newB = msg.value + this.getBalacnce();
    uint256 oldFavPerc = (i_favorite.line/100)* this.getBalacnce();
    if (wantsFavorite) {
      s_favoritters.push(SingleBet(payable(msg.sender), i_favorite.line, msg.value));
      i_favorite.line = ((oldFavPerc * newB) / this.getBalacnce()) * 100;
      i_dog.line = 100 - i_favorite.line;
    } else {
      s_doggers.push(SingleBet(payable(msg.sender), i_dog.line, msg.value));
      i_dog.line = ((oldFavPerc * newB) / this.getBalacnce()) * 100;
      i_favorite.line = 100 - i_dog.line;
    }

    emit BetEnter(msg.sender);
  }

  function getBalacnce() external view returns (uint8) {
    address(this).balance;
  }

  function chargeHouse() external payable {
      uint256 favePerc = i_favorite.line / 100;
      s_favoritters.push(SingleBet(payable(msg.sender), i_favorite.line, favePerc * msg.value));
      s_doggers.push(SingleBet(payable(msg.sender), i_dog.line, (100 - favePerc) * msg.value));
      if (!this.i_initizialized) {
        this.i_initizialized = true;
      } 
  }

}