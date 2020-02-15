///////////////////////////////////////////////////////////////////////////////////
////                              RedressInterface                              ///
///////////////////////////////////////////////////////////////////////////////////
///                                                                             ///
/// Record compensation and release compensation.                               ///
///                                                                             ///
///////////////////////////////////////////////////////////////////////////////////
///                                                          Mr.K by 2019/08/01 ///
///////////////////////////////////////////////////////////////////////////////////

pragma solidity >=0.5.0 <0.6.0;

interface RedressInterface {

    function RedressInfo() external view returns ( uint256 total, uint256 withdrawed, uint256 cur );

    function WithdrawRedress() external returns (uint256);

    event Event_AddNewRedress( address indexed owner, uint256 indexed amount, uint256 total );

    event Event_WithdrawRedress(address indexed owner, uint256 indexed amount, uint256 total );

    function API_AddRedress( address who, uint256 amount ) external;
}
