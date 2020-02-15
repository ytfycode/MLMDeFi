///////////////////////////////////////////////////////////////////////////////////
////                     Withdraw fee calculation contract                      ///
///////////////////////////////////////////////////////////////////////////////////
///                                                                             ///
/// This contract is used to store the calculation information of relevant      ///
/// handling fees when withdrawing ETH from ETH Player, and provide a updating  ///
/// converting ratio between ETH and EPK.                                       ///
///                                                                             ///
///////////////////////////////////////////////////////////////////////////////////
///                                                          Mr.K by 2019/08/01 ///
///////////////////////////////////////////////////////////////////////////////////

pragma solidity >=0.5.0 <0.6.0;

interface CostInterface {

    //Get current exchange ratio，1ETH：xx
    function CurrentCostProp() external view returns (uint256);

    //Get the corresponding value of ERC-20 token handling fee
    function WithdrawCost(uint256 value) external view returns (uint256);
    
}
