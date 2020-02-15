pragma solidity >=0.5.0 <0.6.0;

import "./interface/token/ERC20Interface.sol";
import "./interface/ticket/TicketInterface.sol";
import "./InternalModule.sol";

contract ERC20Token is ERC20Interface, InternalModule {

    /// Members ///
    string  public name                     = "Name";
    string  public symbol                   = "Symbol";
    uint8   public decimals                 = 18;
    uint256 public totalSupply              = 1000000000 * 10 ** 18;
    uint256 constant private MAX_UINT256    = 2 ** 256 - 1;

    uint256 private constant brunMaxLimit = (1000000000 * 10 ** 18) - (10000000 * 10 ** 18);

    /// DataStructure ///
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    /// Events ///
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// Constructor ///
    constructor(string memory tokenName, string memory tokenSymbol, uint256 tokenTotalSupply, uint256 mint) public {

        name = tokenName;
        symbol = tokenSymbol;
        totalSupply = tokenTotalSupply;

        balances[_contractOwner] = mint;
        balances[address(this)] = tokenTotalSupply - mint;
    }

    /// Methods ///
    function transfer(address _to, uint256 _value) public
    returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public
    returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view
    returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view
    returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /////////////////////////////////////////////////////////////////
    // TicketInterface IMPL /////////////////////////////////////////
    /////////////////////////////////////////////////////////////////
    uint256 private ticketPrice = 60000000000000000000;

    mapping( address => bool ) private _paymentTicketAddrMapping;

    function PaymentTicket() external {

        require( _paymentTicketAddrMapping[msg.sender] == false, "ERC20_ERR_001");
        require( balances[msg.sender] >= ticketPrice, "ERC20_ERR_002");

        balances[msg.sender] -= ticketPrice;

        //燃烧
        if ( balances[address(0x0)] == brunMaxLimit ) {

            ///已经到达最大燃烧之，直接入账
            balances[_contractOwner] += ticketPrice;

        } else if ( balances[address(0x0)] + ticketPrice >= brunMaxLimit ) {

            ///支付本次门票后到达最大燃烧值
            balances[_contractOwner] += (balances[address(0x0)] + ticketPrice) - brunMaxLimit;
            balances[address(0x0)] = brunMaxLimit;

        } else {

            ///支付本次门票后依然未到最大燃烧值
            balances[address(0x0)] += ticketPrice;

        }

        _paymentTicketAddrMapping[msg.sender] = true;
    }

    function HasTicket( address ownerAddr ) external view returns (bool) {
        return _paymentTicketAddrMapping[ownerAddr];
    }

}
