///////////////////////////////////////////////////////////////////////////////////
////                                Resonance contract                          ///
///////////////////////////////////////////////////////////////////////////////////
///                                                                             ///
/// This contract is used as a query for current resonance round information,   ///
/// history round information and participate in resonance trade.               ///
///                                                                             ///
///////////////////////////////////////////////////////////////////////////////////
///                                                          Mr.K by 2019/08/01 ///
///////////////////////////////////////////////////////////////////////////////////

pragma solidity >=0.5.0 <0.6.0;

interface TokenChangerInterface {

    //Get the specified resonance round information
    function ChangeRoundAt(uint8 rid) external view returns (uint8 roundID, uint256 total, uint256 prop, uint256 changed);

    //Current resonance round information
    function CurrentRound() external view returns (uint8 roundID, uint256 total, uint256 prop, uint256 changed);

    //Convert Ether to EPK according to current exchange ratio
    function DoChangeToken() external payable;

    //The definition of the event when the conversion is successful
    event Event_ChangedToken(address indexed owner, uint8 indexed round, uint256 indexed value);
}
