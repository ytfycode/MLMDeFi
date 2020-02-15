///////////////////////////////////////////////////////////////////////////////////
////                     Standard ERC-20 token contract (EPK)                   ///
///////////////////////////////////////////////////////////////////////////////////
///                                                                             ///
/// Standard ERC-20 token contract definition as mentioned above                ///
///                                                                             ///
///////////////////////////////////////////////////////////////////////////////////
///                                                          Mr.K by 2019/08/01 ///
///////////////////////////////////////////////////////////////////////////////////

pragma solidity >=0.5.0 <0.6.0;

contract ERC20Interface
{
    uint256 public totalSupply;
    string  public name;
    uint8   public decimals;
    string  public symbol;

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// only call in internal module contranct instance
    function API_MoveToken(address _from, address _to, uint256 _value) external;
}
