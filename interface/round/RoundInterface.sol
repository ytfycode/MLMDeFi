///////////////////////////////////////////////////////////////////////////////////
////                                  Round contract                            ///
///////////////////////////////////////////////////////////////////////////////////
///                                                                             ///
/// Round contract is one of the major contracts within ETH Player, all         ///
/// participation and settlement operations are defined in this contract.       ///
///                                                                             ///
///////////////////////////////////////////////////////////////////////////////////
///                                                          Mr.K by 2019/08/01 ///
///////////////////////////////////////////////////////////////////////////////////

pragma solidity >=0.5.0 <0.6.0;

interface RoundInterface {

    event Event_NewDepositJoined( address indexed owner, uint256 indexed amount, uint256 indexed total );

    //Check the current game round. Users need to send at least one ETH to join the game and make sure that they are not currently participating in other rounds.
    function Join() external payable;

    //Get the round information that users are currently participating in
    function GetCurrentRoundInfo( address owner ) external view returns ( uint256 stime, uint256 etime, uint256 value, bool redressable);

    //Settle the profits of one round when settlement time arrives
    function Settlement() external;

    //Check the referral profits that one address can get
    function DynamicAmountOf( address owner ) external view returns (uint256);

    //Withdraw referral profits
    function WithdrawDynamic() external returns (bool);

    // Anticipated profits of one user
    // v2 unsupport this method
    // function ExpectedRevenue() external view returns (uint256);

    // Gets the user's total input and total withdraw amount of ETH for the current round
    function TotalInOutAmount() external view returns (uint256 inEther, uint256 outEther);

    // Receive compensation
    // v2 unsupport this method
    // function WithdrawRedress() external returns (uint256);

    // Receive compensation
    // v2 unsupport this method
    // function WithdrawRedressAmount() external view returns (uint256 e, uint256 t);

    // When compensation comes into being, it needs to be paid.
    function DrawRedress() external returns (bool);

    function GetRedressInfo() external view returns (uint256 total, bool withdrawable);

    function API_RepaymentTicketDelegate( address owner ) external;
}
