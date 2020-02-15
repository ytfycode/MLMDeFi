pragma solidity >=0.5.0 <0.6.0;

import "./interface/levelsub/LevelSubInterface.sol";
import "./interface/recommend/RecommendInterface.sol";
import "./InternalModule.sol";

// The level difference mode divides users into N levels. Each registration has a level parameter n
contract LevelSub is LevelSubInterface, InternalModule {

    RecommendInterface  private _recommendInf;

    // Maximum traversal depth limit of hierarchy mechanism
    uint256             public _searchReommendDepth = 15;
    // Maximum depth of differential search
    uint256             public _searchLvLayerDepth = 1024;
    // Differential parameter, percent
    uint256[]           public _subProfits = [0, 5, 5, 5, 5];
    // Level bonus percentage
    uint256             public _equalLvProp = 10;
    // Number of level awards
    uint256             public _equalLvMaxLimit = 3;
    // Level reward search depth
    uint256             public _equalLvSearchDepth = 10;
    // Number of eth required to purchase LV1 level
    uint256             public _paymentLv1Prices = 50 ether;

    mapping(uint256 => uint256) public _totalManagerCount;

    address []          public _merAddressList;
    mapping ( address => uint256 ) _ownerLevelsMapping;

    constructor( RecommendInterface recomm ) public {
        _recommendInf = recomm;
    }

    /// add in v3
    uint256 public _paymentedCount = 0;
    function PaymentToUpgradeLv1() external payable {

        if ( _paymentedCount / 20 > 5 ) {
            require ( msg.value >= _paymentLv1Prices );
        } else {
            require ( msg.value >= 10 ether + (10 ether * (_paymentedCount / 20 )));
        }

        require ( _ownerLevelsMapping[msg.sender] == 0 );

        _ownerLevelsMapping[msg.sender] = 1;
        _totalManagerCount[1]++;
        _merAddressList.push(msg.sender);
        _paymentedCount++;

        address payable recver = address( uint160( address(0xd2A01281C80b1D01b6bEE0D85Bc30db82E82bB43) ) );

        recver.transfer(msg.value);
    }

    function GetLevelSubValues() external view returns (uint256[] memory _values) {
        return _subProfits;
    }

    function LevelOf( address _owner ) public view returns (uint256 lv) {
        return _ownerLevelsMapping[_owner];
    }

    // Whether the conditions for updating the user's level are met
    function CanUpgradeLv( address _rootAddr ) public view returns (int) {

        //若已是设定的最高等级，不允许继续升级
        require( _ownerLevelsMapping[_rootAddr] < _subProfits.length - 1, "Level Is Max" );

        uint256 effCount = 0;
        address[] memory referees;

        if ( _ownerLevelsMapping[_rootAddr] == 0 ) {

            referees = _recommendInf.RecommendList(_rootAddr, 0);

            for (uint i = 0; i < referees.length; i++) {

                if ( _recommendInf.IsValidMember( referees[i] ) ) {

                    //PROD VALUE
                    if ( ++effCount >= 10 ) {
                        break;
                    }
                }
            }

            //PROD VALUE
            if ( effCount < 10 ) {
                //表示第一个条件不满足
                return -1;
            }

            //PROD VALUE
            if ( _recommendInf.InvestTotalEtherOf(msg.sender) < 20 ether ) {
                return -2;
            }

            //PROD VALUE
            if ( _recommendInf.ValidMembersCountOf(msg.sender) < 200 ) {
                return -3;
            }

            return 1;
        }
        // Lv.n(n != 0) -> Lv.(n + 1)
        else {

            //target level
            uint256 targetLv = _ownerLevelsMapping[_rootAddr] + 1;

            referees = _recommendInf.RecommendList(_rootAddr, 0);

            uint256 levelUpEffCount = 2;
            if ( targetLv > 2) {
                levelUpEffCount = 3;
            }

            for ( uint i = 0; i < referees.length && effCount < levelUpEffCount; i++ ) {

                if ( LevelOf( referees[i] ) >= targetLv - 1 ) {

                    effCount ++;
                    continue;

                } else {

                    bool finded = false;
                    for ( uint d = 0; d < _searchReommendDepth - 1 && !finded; d++ ) {

                        address[] memory grandchildren = _recommendInf.RecommendList( referees[i], d );

                        for ( uint256 z = 0; z < grandchildren.length && !finded; z++ ) {

                            if ( LevelOf( grandchildren[z] ) >= targetLv - 1 ) {
                                finded = true;
                            }

                        }
                    }

                    if ( finded ) {
                        effCount ++;
                    }
                }
            }

            if ( effCount >= levelUpEffCount ) {
                return int(targetLv);
            } else {
                return -1;
            }

        }
    }

    // upgrade？
    function DoUpgradeLv( ) external returns (uint256) {

        int256 canMakeToTargetLv = CanUpgradeLv(msg.sender);

        if ( canMakeToTargetLv == 1) {
            _merAddressList.push(msg.sender);
        }

        if ( canMakeToTargetLv > 0 ) {
            _ownerLevelsMapping[msg.sender] = uint256(canMakeToTargetLv);
            _totalManagerCount[ uint256(canMakeToTargetLv) ]++;
        }

        return _ownerLevelsMapping[msg.sender];
    }

    /// Calculation of revenue is not used for sending but only for providing revenue calculation. As for whether to send revenue, the above contract decides
    /// For calculation of differential income, the rules are defined as:
    /// Search from the root address up to a total of [searchlvlayerdeth layer. If you find a user with a higher level than yourself, send the level difference
    /// V2: a new level reward is added. The judgment rule is that the settlement user is the nearest manager n level L, and then the manager is the starting node,
    /// Search up 10 layers and get 10% of N revenue from users with 0-3 levels < = L
    function ProfitHandle( address _owner, uint256 _amount ) external view
    returns ( uint256 len, address[] memory addrs, uint256[] memory profits ) {

        uint256[] memory tempProfits = _subProfits;

        address parent = _recommendInf.GetIntroducer(_owner);

        if ( parent == address(0x0) ) {
            return (0, new address[](0), new uint256[](0));
        }

        /// V1
        // len = _subProfits.length;
        // addrs = new address[](len);
        // profits = new uint256[](len);

        len = _subProfits.length + _equalLvMaxLimit;
        addrs = new address[](len);
        profits = new uint256[](len);

        uint256 currlv = 0;
        uint256 plv = _ownerLevelsMapping[parent];

        address nearestAddr;
        uint256 nearestProfit;

        for ( uint i = 0; i < _searchLvLayerDepth; i++ ) {

            //Differential income determination
            //Looking for the first user with higher level than yourself
            //And the level difference of corresponding level has not been claimed
            if ( plv > currlv && tempProfits[plv] > 0 ) {

                uint256 psum = 0;

                for ( uint x = plv; x > 0; x-- ) {

                    psum += tempProfits[x];

                    tempProfits[x] = 0;
                }

                if ( psum > 0 ) {

                    if ( nearestAddr == address(0x0) && plv > 1 ) {
                        nearestAddr = parent;
                        nearestProfit = (_amount * psum) / 100;
                    }

                    addrs[plv] = parent;
                    profits[plv] = (_amount * psum) / 100;
                }
            }

            parent = _recommendInf.GetIntroducer(parent);

            if ( plv >= _subProfits.length - 1 || parent == address(0x0) ) {
                break;
            }

            plv = _ownerLevelsMapping[parent];
        }

        uint256 L = _ownerLevelsMapping[nearestAddr];

        if ( nearestAddr != address(0x0) && L > 1 && nearestProfit > 0 ) {

            parent = nearestAddr;

            uint256 indexOffset = _subProfits.length;

            for (uint j = 0; j < _equalLvSearchDepth; j++) {

                parent = _recommendInf.GetIntroducer(parent);
                plv = _ownerLevelsMapping[parent];

                if ( plv <= L && plv > 1 ) {

                    addrs[indexOffset] = parent;
                    profits[indexOffset] = (nearestProfit * _equalLvProp) / 100;

                    if ( indexOffset + 1 >= len ) {
                        break;
                    }

                    indexOffset++;
                }
            }

        }

        return (len, addrs, profits);
    }

    //Set the maximum depth of differential reward upward search (default: 1024)
    function Owner_SetLevelSearchDepth( uint256 d ) external OwnerOnly {
        _searchLvLayerDepth = d;
    }

    //Set the maximum depth of down lookup in upgrade lookup (default: 9).
    //This value cannot exceed the maximum record value of recommended level defined in the recommended contract
    function Owner_SetSearchRecommendDepth( uint256 d ) external OwnerOnly {
        _searchReommendDepth = d;
    }

    ///P: level reward percentage, LG. (10: for 10%, 200 for 200%, once and so on, negative number output is not allowed)
    ///Limit: number of level awards
    ///Depth: search depth of level reward
    function Owner_SetEqualLvRule( uint256 p, uint256 limit, uint256 depth ) external OwnerOnly {
        _equalLvProp = p;
        _equalLvMaxLimit = limit;
        _equalLvSearchDepth = depth;
    }

    function Owner_SetLevelSubValues( uint256 lv, uint256 value ) external OwnerOnly {
        _subProfits[lv] = value;
    }

    function Owner_SetPaymentLv1Prices( uint256 prices ) external OwnerOnly {
        _paymentLv1Prices = prices;
    }
}
