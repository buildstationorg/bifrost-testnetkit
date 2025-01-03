// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.25;

import "src/MoonbeamSlpx.sol";

contract XcmOracle {

    /*//////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/
    address public owner;

    struct PoolInfo {
        uint256 assetAmount;
        uint256 vAssetAmount;
    }

    struct RateInfo {
        uint8 mintRate;
        uint8 redeemRate;
    }

    RateInfo public rateInfo;

    address public slxAddress;

    address public sovereignAddress;

    mapping(bytes2 => PoolInfo) public tokenPool;

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        address _SlxAddress,
        address _SovereignAddress,
        address _owner  
    ) {
        slxAddress = _SlxAddress;
        sovereignAddress = _SovereignAddress;
        owner = _owner;
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// Bifrost will set a fee and the data will be consistent with Bifrost Chain.
    function setRate(uint8 _mintRate, uint8 _redeemRate) public onlyOwner {
        rateInfo.mintRate = _mintRate;
        rateInfo.redeemRate = _redeemRate;
    }

    /// Setting up data with XCM.
    function setTokenAmount(
        bytes2 _currencyId,
        uint256 _assetAmount,
        uint256 _vAssetAmount
    ) public {
        require(_msgSender() == sovereignAddress, "No permission");
        PoolInfo storage poolInfo = tokenPool[_currencyId];
        poolInfo.assetAmount = _assetAmount;
        poolInfo.vAssetAmount = _vAssetAmount;
    }

    function getVTokenByToken(
        address _assetAddress,
        uint256 _assetAmount
    ) public view whenNotPaused returns (uint256) {
        bytes2 currencyId = getCurrencyIdByAssetAddress(_assetAddress);
        PoolInfo memory poolInfo = tokenPool[currencyId];
        require(
            poolInfo.vAssetAmount != 0 && poolInfo.assetAmount != 0,
            "Not ready"
        );
        uint256 mintFee = (rateInfo.mintRate * _assetAmount) / 10000;
        uint256 assetAmountExcludingFee = _assetAmount - mintFee;
        uint256 vAssetAmount = (assetAmountExcludingFee *
            poolInfo.vAssetAmount) / poolInfo.assetAmount;
        return vAssetAmount;
    }

    function getTokenByVToken(
        address _assetAddress,
        uint256 _vAssetAmount
    ) public view whenNotPaused returns (uint256) {
        bytes2 currencyId = getCurrencyIdByAssetAddress(_assetAddress);
        PoolInfo memory poolInfo = tokenPool[currencyId];
        require(
            poolInfo.vAssetAmount != 0 && poolInfo.assetAmount != 0,
            "Not ready"
        );
        uint256 redeemFee = (rateInfo.redeemRate * _vAssetAmount) / 10000;
        uint256 vAssetAmountExcludingFee = _vAssetAmount - redeemFee;
        uint256 assetAmount = (vAssetAmountExcludingFee *
            poolInfo.assetAmount) / poolInfo.vAssetAmount;
        return assetAmount;
    }

    function getCurrencyIdByAssetAddress(
        address _assetAddress
    ) public view returns (bytes2) {
        (bytes2 currencyId, uint256 _d) = MoonbeamSlpx(slxAddress)
            .addressToAssetInfo(_assetAddress);
        require(currencyId != 0x0000, "Not found");
        return currencyId;
    }
}