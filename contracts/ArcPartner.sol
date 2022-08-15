// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ArcPartner {
    address private _partner;

    // Access modifier for partner-only functionality
    modifier onlyPartner() {
        require(_partner == msg.sender, "ARC:Denied");
        _;
    }

    /**
     * @dev Returns the address of the current partner.
     */
    function partner() public view returns (address) {
        return _partner;
    }

    /**
     * @dev transfer partner account by own
     * @param account_ address
     */
    function transferPartner(address account_) public onlyPartner {
        _partner = account_;
    }

    /**
     * @dev Set partner
     */
    function _setPartner(address partner_) internal {
        _partner = partner_;
    }
}
