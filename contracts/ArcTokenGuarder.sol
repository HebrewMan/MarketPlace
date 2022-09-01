// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IBEP20.sol";
import "./ArcGuarder.sol";

contract ArcTokenGuarder is ArcGuarder {
    /**
     * @dev In case of accident or emergency, transfer the assets of this contract.emergency only!
     * @param token Token of the asset to be migrated
     */
    function emergencyMigrateAsset(address token) public onlyRole(2) {
        uint256 balance = IBEP20(token).balanceOf(address(this));
        require(balance > 0, "ARC:NO_BALANCE");
        IBEP20(token).transfer(msg.sender, balance);
    }

    /**
     * @dev In case of accident or emergency, transfer the ETH assets of this contract.emergency only!
     */
    function emergencyMigrateAssetETH() public onlyRole(2) {
        uint256 balance = address(this).balance;
        require(balance > 0, "ARC:NO_BALANCE");
        address payable _cashier = payable(msg.sender);
       _cashier.transfer(balance);
    }
}
