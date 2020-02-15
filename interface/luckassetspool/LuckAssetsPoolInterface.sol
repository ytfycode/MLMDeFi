pragma solidity >=0.5.0 <0.6.0;

interface LuckAssetsPoolInterface {

    /// get my reward prices
    function RewardsAmount() external view returns (uint256);

    /// withdraw my all rewards
    function WithdrawRewards() external returns (uint256);

    function InPoolProp() external view returns (uint256);

    /// append user to latest.
    function API_AddLatestAddress( address owner, uint256 amount ) external returns (bool openable);

    /// only in LuckAssetsPoolA
    function NeedPauseGame() external view returns (bool);
    function API_Reboot() external returns (bool);

    /// only in LuckAssetsPoolB
    function API_GameOver() external returns (bool);

    event Log_Winner( address owner, uint256 when, uint256 amount);
}
