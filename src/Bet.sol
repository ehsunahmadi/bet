// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

struct Pick {
  uint8 line;
  string name;
}

struct SingleBet {
  address payable bettorAddress;
  uint8 bettorLine;
  uint256 amount;
}

error Bet__SendMoreToBet(unit256 indexed amount);
error Bet__SendLessToBet(unit256 indexed amount);


contract Bet {
  uint8 public constant MINIMUM_BET = 0.005 ether;
  // uint8 public constant FEE_PERCENTAGE = uint8(1) / uint8(10);

  uint256 public immutable i_startUpdating;
  uint256 public immutable i_interval;
  uint256 private s_lastTimeStamp;

  Pick public i_favorite;
  Pick public i_dog;

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
    if (msg.value < MINIMUM_BET) {
      revert Bet__SendMoreToBet(this.MINIMUM_BET);
    }

    if (msg.value > ((this.getBalacnce()*100)/(wantsFavorite ? i_favorite.line : i_dog.line))) {
        revert Bet__SendLessToBet();
    }

    if (wantsFavorite) {
      s_favoritters.push(SingleBet(payable(msg.sender), i_favorite.line));
      uint8 oldFavPerc = ((i_favorite.line/100)* this.getBalacnce();
      newB = message.value + this.getBalacnce();
      i_favorite.line = ((p * newB) / this.getBalacnce()) * 100;
      i_dog.line = 100 - i_favorite.line;
    } else {
      s_doggers.push(SingleBet(payable(msg.sender), i_dog.line));
      i_dog.line = ((p * newB) / this.getBalacnce()) * 100;
      i_favorite.line = 100 - i_dog.line;
    }

    emit BetEnter(msg.sender);
  }

  function getBalacnce() external view returns (uint8) {
    adress(this).balance;
  }

  function chargeHouse() external payable {
      favePerc uint8 = i_favorite.line / 100
      s_favoritters.push(SingleBet(payable(msg.sender), i_favorite.line, favePerc * msg.value));
      s_doggers.push(SingleBet(payable(msg.sender), (100 - favePerc) * msg.value));
  }

}