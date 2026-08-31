// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.4.10;

contract tokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract Ownable {
  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  address public owner;

  function transferOwnership(address _newOwner) external onlyOwner {
    owner = _newOwner;
  }
}

contract Child is Ownable {
  function Child(uint256 _totalSupply, string _name, string _symbol, string _description, string _ipfs_hash) public Ownable() {
    balanceOf[msg.sender] = _totalSupply;
    totalSupply = _totalSupply;
    name = _name;
    symbol = _symbol;
    description = _description;
    ipfs_hash = _ipfs_hash;
    decimals = 0;
  }

  string public standard = "Token 0.1";
  string public name;
  string public symbol;
  string public ipfs_hash;
  string public description;
  bool public isLocked;
  uint8 public decimals;
  uint256 public totalSupply;
  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowance[msg.sender][_spender] = _value;
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
    if (balanceOf[_from] < _value) throw;
    if (balanceOf[_to] + _value < balanceOf[_to]) throw;
    if (_value > allowance[_from][msg.sender]) throw;
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    allowance[_from][msg.sender] -= _value;
    Transfer(_from, _to, _value);
    return true;
  }

  function mintToken(address _to, uint256 _value) external onlyOwner {
    require(!isLocked);
    balanceOf[_to] += _value;
    totalSupply += _value;
    Transfer(address(0), address(this), _value);
    Transfer(address(this), _to, _value);
  }

  function setDescription(string _newDescription) public onlyOwner {
    description = _newDescription;
  }

  function transfer(address _to, uint256 _value) external {
    if (balanceOf[msg.sender] < _value) throw;
    if (balanceOf[_to] + _value < balanceOf[_to]) throw;
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
  }

  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool) {
    tokenRecipient _receiveApprovalTarget = tokenRecipient(_spender);
    if (approve(_spender, _value)) {
      _receiveApprovalTarget.receiveApproval(msg.sender, _value, address(this), _extraData);
      return true;
    }
  }

  function lock() external onlyOwner {
    isLocked = true;
  }

  function() external {
    revert();
  }
}

contract CardTokenFactory {
  function CardTokenFactory() public {
    RareCount = 1;
  }

  address[] public Rares;
  uint256 public RareCount;

  function createRare(uint256 _totalSupply, string _name, string _symbol, string _description, string _ipfs_hash) public returns (address) {
    address childAddress = address(new Child(_totalSupply, _name, _symbol, _description, _ipfs_hash));
    Rares.push(childAddress);
    RareCount += 1;
    Child(childAddress).transferOwnership(msg.sender);
    Child(childAddress).transfer(msg.sender, _totalSupply);
    return childAddress;
  }

  function() external {
    revert();
  }
}
