// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../../token/IERC20.sol';
import '../../pool/IPool.sol';
import '../../library/SafeERC20.sol';
import '../../utils/NameVersion.sol';

contract ClientImplementation is NameVersion {

    using SafeERC20 for IERC20;

    address public immutable broker;

    address public immutable tokenXVS;

    modifier _onlyBroker_() {
        require(msg.sender == broker, 'ClientImplementation: only broker');
        _;
    }

    constructor (address broker_, address tokenXVS_) NameVersion('ClientImplementation', '3.0.1') {
        broker = broker_;
        tokenXVS = tokenXVS_;
    }

    function addLiquidity(address pool, address asset, uint256 amount, IPool.OracleSignature[] memory oracleSignatures)
    external payable _onlyBroker_
    {
        if (asset == address(0)) {
            IPool(pool).addLiquidity{value: amount}(address(0), 0, oracleSignatures);
        } else {
            _approvePool(pool, asset);
            IPool(pool).addLiquidity(asset, amount, oracleSignatures);
        }
    }

    function removeLiquidity(address pool, address asset, uint256 amount, IPool.OracleSignature[] memory oracleSignatures)
    external _onlyBroker_
    {
        IPool(pool).removeLiquidity(asset, amount, oracleSignatures);
    }

    function addMargin(address pool, address asset, uint256 amount, IPool.OracleSignature[] memory oracleSignatures)
    external payable _onlyBroker_
    {
        if (asset == address(0)) {
            IPool(pool).addMargin{value: amount}(address(0), 0, oracleSignatures);
        } else {
            _approvePool(pool, asset);
            IPool(pool).addMargin(asset, amount, oracleSignatures);
        }
    }

    function removeMargin(address pool, address asset, uint256 amount, IPool.OracleSignature[] memory oracleSignatures)
    external _onlyBroker_
    {
        IPool(pool).removeMargin(asset, amount, oracleSignatures);
    }

    function trade(address pool, string memory symbolName, int256 tradeVolume, int256 priceLimit, IPool.OracleSignature[] memory oracleSignatures)
    external _onlyBroker_
    {
        IPool(pool).trade(symbolName, tradeVolume, priceLimit, oracleSignatures);
    }

    function transfer(address asset, address to, uint256 amount) external _onlyBroker_ {
        if (asset == address(0)) {
            (bool success, ) = payable(to).call{value: amount}('');
            require(success, 'ClientImplementation.transfer: send ETH fail');
        } else {
            IERC20(asset).safeTransfer(to, amount);
        }
    }

    function claimInterestAsLp(address pool) external _onlyBroker_ {
        IPool(pool).claimVenusLp(address(this));
        IERC20(tokenXVS).safeTransfer(broker, IERC20(tokenXVS).balanceOf(address(this)));
    }

    function claimInterestAsTrader(address pool) external _onlyBroker_ {
        IPool(pool).claimVenusTrader(address(this));
        IERC20(tokenXVS).safeTransfer(broker, IERC20(tokenXVS).balanceOf(address(this)));
    }

    function _approvePool(address pool, address asset) internal {
        uint256 allowance = IERC20(asset).allowance(address(this), pool);
        if (allowance == 0) {
            IERC20(asset).safeApprove(address(pool), type(uint256).max);
        }
    }

}
