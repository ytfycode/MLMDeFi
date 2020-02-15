///////////////////////////////////////////////////////////////////////////////////
////                             Team leader contract                           ///
///////////////////////////////////////////////////////////////////////////////////
///                                                                             ///
/// This contract is used to set the upgrade condition of team leader levels    ///
/// and the anticipated profits of corresponding team leader level.             ///
///                                                                             ///
///////////////////////////////////////////////////////////////////////////////////
///                                                          Mr.K by 2019/08/01 ///
///////////////////////////////////////////////////////////////////////////////////

pragma solidity >=0.5.0 <0.6.0;

interface LevelSubInterface {

    //Get the team leader levels of specified addresses
    function LevelOf( address _owner ) external view returns (uint256 lv);

    //Only updating the user's own game level when checking if they have met the updating conditions and do not implicate the game level of their referrals. If their referrals have met the updating conditions, then calls this method to upgrade their levels.
    function CanUpgradeLv( address _rootAddr ) external view returns (int);

    //Upgrade only one level at a time, if a user has met the condition which allow him or her to upgrade two levels, then call this method twice
    function DoUpgradeLv( ) external returns (uint256);

    //Only used for calculating profits, not for sending profits. As to whether to send profits, the above contract defines the calculation method of different levels with the rule defined as: search up from the Root address for a total of _ searchLvLayerDepth level. If a higher level user is found, then the profits will be sent.
    function ProfitHandle( address _owner, uint256 _amount ) external view returns ( uint256 len, address[] memory addrs, uint256[] memory profits );

    function PaymentToUpgradeLv1() external payable;
}
