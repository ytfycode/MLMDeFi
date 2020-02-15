///////////////////////////////////////////////////////////////////////////////////
////                          Data statistics contract                          ///
///////////////////////////////////////////////////////////////////////////////////
///                                                                             ///
/// Record the statistics and operating data for the complete set of contracts  ///
/// within ETH Player                                                           ///
///                                                                             ///
///////////////////////////////////////////////////////////////////////////////////
///                                                          Mr.K by 2019/08/01 ///
///////////////////////////////////////////////////////////////////////////////////

pragma solidity >=0.5.0 <0.6.0;

interface StatisticsInterface {

    //Get static profits record
    function GetStaticProfitTotalAmount() external view returns (uint256);

    //Get the cumulative amount of referral profits
    function GetDynamicProfitTotalAmount() external view returns (uint256);

    function API_AddStaticTotalAmount( address player, uint256 value ) external;

    function API_AddDynamicTotalAmount( address player, uint256 value ) external;

    function API_AddWinnerCount() external;
}
