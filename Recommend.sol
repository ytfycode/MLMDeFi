pragma solidity >=0.5.0 <0.6.0;

import "./interface/recommend/RecommendInterface.sol";
import "./InternalModule.sol";

contract Recommend is RecommendInterface, InternalModule {

    // Maximum record recommendation relationship level
    uint256 private _recommendDepthLimit = 15;

    // Search structure upward
    mapping ( address => address ) _recommerMapping;

    // Search structure down
    mapping ( address => mapping( uint256 => address[] )) _recommerList;

    // Recommended valid user search
    mapping ( address => uint256 ) _vaildMemberCountMapping;

    // Effective user search
    mapping ( address => bool ) _vaildMembersMapping;

    // Cumulative input record
    mapping ( address => uint256 ) _despositTotalMapping;

    mapping ( address => uint256 ) _recommerCountMapping;

    // Recommendation code
    mapping ( bytes6 => address ) _shortCodeMapping;

    mapping ( address => bytes6 ) _addressShotCodeMapping;

    constructor( uint256 depth ) public {

        _recommendDepthLimit = depth;

        address rootAddr = address(0x47a8c1fEDe8474cA3863e030Dfa27848F9F299AB);
        bytes6 rootCode = 0x303030303030; // 000000

        /// Default Recommend Relations
        internalBind(rootAddr, address(0xFF));
        _shortCodeMapping[rootCode] = rootAddr;
        _addressShotCodeMapping[rootAddr] = rootCode;
    }

    function GetDepth() external view returns (uint256 depth) {
      return _recommendDepthLimit;
    }

    function internalBind( address a, address r ) internal returns (bool) {

        _recommerMapping[a] = r;

        address parent = r;

        for ( uint i = 0; i < _recommendDepthLimit; i++ ) {

            _recommerList[parent][i].push(a);

            _recommerCountMapping[parent] ++;

            parent = _recommerMapping[parent];

            if ( parent == address(0x0) ) {
                break;
            }
        }

        return true;
    }

    function GetIntroducer( address _owner ) external view returns (address) {
        return _recommerMapping[_owner];
    }

    function RecommendList( address _owner, uint256 depth ) external view returns ( address[] memory list ) {
        return _recommerList[_owner][depth];
    }

    function RegisterShortCode( bytes6 shortCode ) external returns (bool) {

        require( _shortCodeMapping[shortCode] == address(0x0), "RCM_ERR_001" );

        require( _addressShotCodeMapping[msg.sender] == bytes6(0x0), "RCM_ERR_002" );

        _shortCodeMapping[shortCode] = msg.sender;
        _addressShotCodeMapping[msg.sender] = shortCode;

        return true;
    }

    function ShortCodeToAddress( bytes6 shortCode ) external view returns (address) {
        return _shortCodeMapping[shortCode];
    }

    function AddressToShortCode( address _addr ) external view returns (bytes6) {
        return _addressShotCodeMapping[_addr];
    }

    function TeamMemberTotal( address _addr ) external view returns (uint256) {
        return _recommerCountMapping[_addr];
    }

    function IsValidMember( address _addr ) external view returns (bool) {
        return _vaildMembersMapping[_addr];
    }

    function ValidMembersCountOf( address _addr ) external view returns (uint256) {
        return _vaildMemberCountMapping[_addr];
    }

    function InvestTotalEtherOf( address _addr ) external view returns (uint256) {
        return _despositTotalMapping[_addr];
    }

    function DirectValidMembersCount( address _addr ) external view returns (uint256){

        uint256 count = 0;

        address[] storage rlist = _recommerList[_addr][0];

        for ( uint i = 0; i < rlist.length; i++ ) {

            if ( _vaildMembersMapping[rlist[i]] ) {
                count ++;
            }

        }

        return count;
    }

    function Bind( address sender, address _recommer ) internal returns (bool) {

        require( _recommer != sender, "RCM_ERR_003" );

        require( _recommerMapping[sender] == address(0x0), "RCM_ERR_004" );

        require( _recommerMapping[_recommer] != address(0x0), "RCM_ERR_005");

        uint256 rsize;
        uint256 ssize;
        address safeAddr = sender;
        assembly {
            rsize := extcodesize(_recommer)
            ssize := extcodesize(safeAddr)
        }

        require( rsize == 0 && ssize == 0, "DAO_Warning" );

        _recommerMapping[sender] = _recommer;

        address parent = _recommer;

        for ( uint i = 0; i < _recommendDepthLimit; i++ ) {

            _recommerList[parent][i].push(sender);

            _recommerCountMapping[parent] ++;

            parent = _recommerMapping[parent];

            if ( parent == address(0x0) ) {
                break;
            }
        }

        return true;
    }

    function API_MarkValid( address _addr, uint256 _evalue ) external APIMethod {

        if ( _vaildMembersMapping[_addr] == false ) {

            address parent = _recommerMapping[_addr];

            for ( uint i = 0; i < _recommendDepthLimit; i++ ) {

                _vaildMemberCountMapping[parent] ++;

                parent = _recommerMapping[parent];

                if ( parent == address(0x0) ) {
                    break;
                }
            }

            _vaildMembersMapping[_addr] = true;
        }

        _despositTotalMapping[_addr] += _evalue;
    }

    function API_BindEx( address _owner, address _recommer, bytes6 shortCode ) external {

        require( _shortCodeMapping[shortCode] == address(0x0), "RCM_ERR_001" );

        require( _addressShotCodeMapping[_owner] == bytes6(0x0), "RCM_ERR_002" );

        _shortCodeMapping[shortCode] = _owner;
        _addressShotCodeMapping[_owner] = shortCode;

        Bind(_owner, _recommer);
    }
}
