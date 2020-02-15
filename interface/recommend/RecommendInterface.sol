///////////////////////////////////////////////////////////////////////////////////
////                         Referral record contract                           ///
///////////////////////////////////////////////////////////////////////////////////
///                                                                             ///
/// Record the referral relationship between accounts, including short version  ///
/// referral code application, query, relationship binding, relationship query, ///
/// quantity query and so on.                                                   ///
///                                                                             ///
///////////////////////////////////////////////////////////////////////////////////
///                                                          Mr.K by 2019/08/01 ///
///////////////////////////////////////////////////////////////////////////////////

pragma solidity >=0.5.0 <0.6.0;

interface RecommendInterface {

    // v2.0 unsupported this method.
    // Bind Referral
    // function Bind( address _recommer ) external returns (bool);

    // Get all recommended addresses list at the level
    function RecommendList( address _owner, uint256 depth ) external view returns (address[] memory list);

    // Get my referral
    function GetIntroducer( address _owner ) external view returns (address);

    // v2.0 unsupported this method.
    // Register a 6-digit referral with uppercase letters and numbers
    // function RegisterShortCode( bytes6 shortCode ) external returns (bool);

    // Get the corresponding wallet address binding with the short version referral code
    function ShortCodeToAddress( bytes6 shortCode ) external view returns (address);

    // Check whether the address corresponds to the short version referral code
    function AddressToShortCode( address _addr ) external view returns (bytes6);

    // Get the total team members of the corresponding address
    function TeamMemberTotal( address _addr ) external view returns (uint256);

    // Get the number of valid users of a team
    function ValidMembersCountOf( address _addr ) external view returns (uint256);

    // Get the total number of ETH one address invests
    function InvestTotalEtherOf( address _addr ) external view returns (uint256);

    // Get the number of valid users one address directly invites
    function DirectValidMembersCount( address _addr ) external view returns (uint256);

    // Determine if it is a valid user
    function IsValidMember( address _addr ) external view returns (bool);

    // Mark one as a valid user and write to the level contract, and record the total number of ETH this user invests
    function API_MarkValid( address _addr, uint256 _evalue ) external;

    // Bind recommer and register short recommecode
    function API_BindEx( address _owner, address _recommer, bytes6 shortCode ) external;

}
