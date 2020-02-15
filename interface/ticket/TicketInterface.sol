///////////////////////////////////////////////////////////////////////////////////
////                           EPK record contract                              ///
///////////////////////////////////////////////////////////////////////////////////
///                                                                             ///
/// Used to pay EPK to unlock accounts, record payment results, and provide a   ///
/// query method for querying whether one account has been unlocked.            ///
///                                                                             ///
///////////////////////////////////////////////////////////////////////////////////
///                                                          Mr.K by 2019/08/01 ///
///////////////////////////////////////////////////////////////////////////////////

pragma solidity >=0.5.0 <0.6.0;

interface TicketInterface {

    // One address needs to have enough EPK to unlock accounts. If one account has been unlocked before, the method will not take effect.
    function RePaymentTicket() external;

    // Determine whether the address pays the ticket and is valid
    function HasTicket( address ownerAddr ) external view returns (bool has, bool isVaild);

    // v2.0 added
    // Activate address
    function ActivateAddress( address recommAddr, bytes6 shortCode ) external;

    function API_NeedClearHistory( address owner ) external returns (bool);

    function API_UpdateLatestDyProfitTime( address owner ) external;

    function API_UpdateLatestSettTime( address owner ) external;

    function API_UpdateLatestJoinTime( address owner ) external;
}
