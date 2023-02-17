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
  FetchingResult,
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
error Bet__AccessDeniedOnlyOwner();
error Bet__YouAreOnTheLosingSide(Status status);


contract Bet {
  uint256 public constant MINIMUM_BET = 0.005 ether;
  // uint8 public constant FEE_PERCENTAGE = uint8(1) / uint8(10);


  uint256 public immutable i_startUpdating;
  uint256 public immutable i_interval;

  address public i_owner;
  Status public  i_status = Status.Idle;
  Pick public i_favorite;
  Pick public i_dog;

  uint256 private s_lastTimeStamp;
  mapping (address => SingleBet) private s_bets;
  
  event BetEnter(address indexed bettor);



  constructor(
    Pick memory favorite,
    Pick memory dog,
    uint256 startUpdating,
    uint256 interval
  ) {
    i_owner = msg.sender;
    i_favorite = favorite;
    i_dog = dog;
    i_startUpdating = startUpdating;
    i_interval = interval;
    s_lastTimeStamp = block.timestamp;
  }

  modifier onlyOwner {
    if (msg.sender != i_owner) {
      revert Bet__AccessDeniedOnlyOwner();
    }
    _;
  }

  function bet(bool wantsFavorite) external payable {

    if (i_status != Status.Initialized) {
      revert Bet__ContracInWrongStatus(i_status);
    }
    
    if (msg.value < MINIMUM_BET) {
      revert Bet__SendMoreToBet(this.MINIMUM_BET());
    }

    uint256 max = (this.getBalacnce()*100)/(wantsFavorite ? i_favorite.line : i_dog.line);
    if (msg.value > max) {
        revert Bet__SendLessToBet(max);
    }

    uint256 newB = msg.value + this.getBalacnce();
    uint256 oldFavPerc = (i_favorite.line/100)* this.getBalacnce();
    if (wantsFavorite) {
      s_bets[msg.sender] = SingleBet(i_favorite.line, msg.value, true);
      i_favorite.line = ((oldFavPerc * newB) / this.getBalacnce()) * 100;
      i_dog.line = 100 - i_favorite.line;
    } else {
      s_bets[msg.sender] = SingleBet(i_favorite.line, msg.value, false);
      i_dog.line = ((oldFavPerc * newB) / this.getBalacnce()) * 100;
      i_favorite.line = 100 - i_dog.line;
    }

    emit BetEnter(msg.sender);
  }

  function getBalacnce() external view returns (uint256) {
      return address(this).balance;
  }

  //TODO: should also set the line
  function initialize() external payable onlyOwner {
    if (i_status != Status.Idle) {
      revert Bet__ContracInWrongStatus(i_status);
    }
    i_status = Status.Initialized;
  }

  function chargeHouse() external payable onlyOwner {
    if (i_status != Status.Initialized) {
      revert Bet__ContracInWrongStatus(i_status);
    }
    uint256 favePerc = i_favorite.line / 100;
    s_bets[msg.sender] = SingleBet(i_favorite.line, (favePerc * msg.value), true);
    s_bets[msg.sender] = SingleBet(i_dog.line, ((100 - favePerc) * msg.value), false);
  }

  function withdraw() external {
    if (i_status < Status.FavoriteWon) {
      revert Bet__ContracInWrongStatus(i_status);
    }

    SingleBet memory winnigBet = s_bets[msg.sender];
    if (i_status == Status.FavoriteWon && winnigBet.favoritist) {
      return payable(msg.sender).transfer(winnigBet.amount * winnigBet.line);
    }
    if (i_status == Status.DogWon && !winnigBet.favoritist) {
      return payable(msg.sender).transfer(winnigBet.amount * winnigBet.line);
    }
    if (i_status == Status.Draw) {
      return payable(msg.sender).transfer(winnigBet.amount);
    }

    revert Bet__YouAreOnTheLosingSide(i_status);
  }

}

