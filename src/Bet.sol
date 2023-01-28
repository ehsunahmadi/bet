// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

struct Pick {
  uint256 line;
  string name;
}

enum Status {
  Idle,
  Initialized,
  FightStarted,
  FavoriteWon,
  DogWon,
  Draw
}

struct SingleBet {
  uint256 line;
  uint256 amount;
  bool favoritist;
}

error Bet__SendMoreToBet(uint256 amount);
error Bet__SendLessToBet(uint256 amount);
error Bet__ContracInWrongStatus(Status status);


contract Bet {
  uint256 public constant MINIMUM_BET = 0.005 ether;
  // uint8 public constant FEE_PERCENTAGE = uint8(1) / uint8(10);


  uint256 public immutable i_startUpdating;
  uint256 public immutable i_interval;

  Status public  i_status = Satus.Idle;
  Pick public i_favorite;
  Pick public i_dog;

  uint256 private s_lastTimeStamp;
  mapping (address => SingleBet) private s_bets;
  address payable[] private s_favoritters;
  address payable[] private s_doggers;
  
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

    if (this.status != Status.Initialized) {
      revert Bet__ContracInWrongStatus(this.i_status);
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
      bets[msg.sender] = SingleBet(i_favorite.line, msg.value, true);
      s_favoritters.push(payable(msg.sender));
      i_favorite.line = ((oldFavPerc * newB) / this.getBalacnce()) * 100;
      i_dog.line = 100 - i_favorite.line;
    } else {
      bets[msg.sender] = SingleBet(i_favorite.line, msg.value, false);
      s_doggers.push(payable(msg.sender));
      i_dog.line = ((oldFavPerc * newB) / this.getBalacnce()) * 100;
      i_favorite.line = 100 - i_dog.line;
    }

    emit BetEnter(msg.sender);
  }

  function getBalacnce() external view returns (uint8) {
    address(this).balance;
  }

  //TODO: onlyOwner dunction that should also set the line
  function initialize() external payable {
    if (this.status != Status.Idle) {
      revert Bet__ContracInWrongStatus(this.i_status);
    }
    this.status = Status.Initialized;
  }

  //TODO: should be onlyOwner
  function chargeHouse() external payable {
    if (this.status != Status.Initialized) {
      revert Bet__ContracInWrongStatus(this.i_status);
    }
    uint256 favePerc = i_favorite.line / 100;
    bets[msg.sender] = SingleBet(i_favorite.line, (favePerc * msg.value), true);
    s_favoritters.push(payable(msg.sender));
    bets[msg.sender] = SingleBet(i_dog.line, ((100 - favePerc) * msg.value), false);
    s_doggers.push(payable(msg.sender));
  }

  function distributeWinnings() public {
    // Check if the fight is over and the winner is known
    if (i_status < Status.FavoriteWon) {
      revert Bet__ContracInWrongStatus(this.i_status);
    }
    //
    if (i_status == Status.FavoriteWon) {
      for (uint256 i = 0; i < s_favoritters.length; i++) {
        s_favoritters[i].transfer(s_bets[s_favoritters[i]].amount * i_favorite.line);
      }
    } else if (i_status == Status.DogWon) {
      for (uint256 i = 0; i < s_doggers.length; i++) {
        s_doggers[i].transfer(s_bets[s_doggers[i]].amount * i_dog.line);
      }
    } else {
      for (uint256 i = 0; i < s_favoritters.length; i++) {
        s_favoritters[i].transfer(s_bets[s_favoritters[i]].amount);
      }
      for (uint256 i = 0; i < s_doggers.length; i++) {
        s_doggers[i].transfer(s_bets[s_doggers[i]].amount);
      }
    }   
  }

}

