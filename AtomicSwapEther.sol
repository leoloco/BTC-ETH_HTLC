pragma solidity ^0.4.24;

contract AtomicSwapEther {

  struct Swap {
    uint256 timelock;
    uint256 value;
    address ethTrader;
    address withdrawTrader;
    bytes32 secretLock;
    string secretKey;
  }

  enum States {
    INVALID,
    INITIATE,
    OPEN,
    CLOSED,
    EXPIRED
  }

  mapping (bytes32 => Swap) private swaps;
  mapping (bytes32 => States) private swapStates;

  event Participate(bytes32 _swapID, address _withdrawTrader,bytes32 _secretLock);
  event Initiate(bytes32 _swapID, bytes32 _secretLock);
  event Expire(bytes32 _swapID);
  event Close(bytes32 _swapID, string _secretKey);

  modifier onlyInvalidSwaps(bytes32 _swapID) {
    require (swapStates[_swapID] == States.INVALID);
    _;
  }

  modifier onlyInitiateSwaps(bytes32 _swapID) {
    require (swapStates[_swapID] == States.INITIATE);
    _;
  }
  modifier onlyOpenSwaps(bytes32 _swapID) {
    require (swapStates[_swapID] == States.OPEN);
    _;
  }
  
  modifier onlyClosedSwaps(bytes32 _swapID) {
    require (swapStates[_swapID] == States.CLOSED);
    _;
  }

  modifier onlyExpirableSwaps(bytes32 _swapID) {
    require (now >= swaps[_swapID].timelock);
    _;
  }

  modifier onlyWithSecretKey(bytes32 _swapID, string _secretKey) {
    // TODO: Require _secretKey length to conform to the spec
    require(swaps[_swapID].secretLock == sha256(abi.encodePacked(_secretKey)));
    _;
  }
    
  modifier onlyInitiator(bytes32 _swapID) {
      require(swaps[_swapID].ethTrader == msg.sender);
      _;
  }
  
  modifier onlywithdrawTrader(bytes32 _swapID) {
      require(swaps[_swapID].withdrawTrader == msg.sender);
      _;
  }
  
  function participate(bytes32 _swapID, address _withdrawTrader, bytes32 _secretLock, uint256 _timelock) public onlyInvalidSwaps(_swapID) payable {
    // Store the details of the swap.
    Swap memory swap = Swap({
      timelock: _timelock + now,
      value: msg.value,
      ethTrader: msg.sender,
      withdrawTrader: _withdrawTrader,
      secretLock: _secretLock,
      secretKey: ""
    });
    swaps[_swapID] = swap;
    swapStates[_swapID] = States.OPEN;

    // Trigger open event.
    emit Participate(_swapID, _withdrawTrader, _secretLock);
  }
    function initiate(bytes32 _swapID, bytes32 _secretLock, uint256 _timelock) public onlyInvalidSwaps(_swapID) payable {
    // Store the details of the swap.
    Swap memory swap = Swap({
      timelock: _timelock + now,
      value: msg.value,
      ethTrader: msg.sender,
      withdrawTrader: msg.sender,
      secretLock: _secretLock,
      secretKey: ""
    });
    swaps[_swapID] = swap;
    swapStates[_swapID] = States.INITIATE;

    // Trigger open event.
    emit Initiate(_swapID, _secretLock);
  }
  
  function setWithdrawTrader(bytes32 _swapID, address _withdrawTrader) public onlyInitiator(_swapID) onlyInitiateSwaps(_swapID){
      swaps[_swapID].withdrawTrader = _withdrawTrader;
      swapStates[_swapID] = States.OPEN;
  }

  function close(bytes32 _swapID, string _secretKey) public onlyOpenSwaps(_swapID) onlyWithSecretKey(_swapID, _secretKey) onlywithdrawTrader(_swapID){
    // Close the swap.
    Swap memory swap = swaps[_swapID];
    swaps[_swapID].secretKey = _secretKey;
    swapStates[_swapID] = States.CLOSED;

    // Transfer the ETH funds from this contract to the withdrawing trader.
    swap.withdrawTrader.transfer(swap.value);

    // Trigger close event.
    emit Close(_swapID, _secretKey);
  }

  function expire(bytes32 _swapID) public onlyOpenSwaps(_swapID) onlyExpirableSwaps(_swapID) onlyInitiator(_swapID) {
    // Expire the swap.
    Swap memory swap = swaps[_swapID];
    swapStates[_swapID] = States.EXPIRED;

    // Transfer the ETH value from this contract back to the ETH trader.
    swap.ethTrader.transfer(swap.value);

     // Trigger expire event.
    emit Expire(_swapID);
  }

  function check(bytes32 _swapID) public view returns (uint256 timelock, uint256 value, address withdrawTrader, bytes32 secretLock) {
    Swap memory swap = swaps[_swapID];
    return (swap.timelock, swap.value, swap.withdrawTrader, swap.secretLock);
  }

  function checkSecretKey(bytes32 _swapID) public view onlyClosedSwaps(_swapID) returns (string secretKey) {
    Swap memory swap = swaps[_swapID];
    return swap.secretKey;
  }
}