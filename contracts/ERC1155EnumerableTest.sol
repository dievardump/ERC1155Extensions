// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Enumerable.sol";

/**
 * @title ERC1155EnumerableTest
 * This mock just publicizes internal functions for testing purposes
 */
contract ERC1155EnumerableTest is ERC1155Enumerable {
    constructor(string memory uri) ERC1155(uri) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function setURI(string memory newuri) public {
        _setURI(newuri);
    }

    function mint(
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public {
        _mint(to, id, value, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public {
        _mintBatch(to, ids, values, data);
    }

    function burn(
        address owner,
        uint256 id,
        uint256 value
    ) public {
        _burn(owner, id, value);
    }

    function burnBatch(
        address owner,
        uint256[] memory ids,
        uint256[] memory values
    ) public {
        _burnBatch(owner, ids, values);
    }

    // so every transfer is accepted
    function isApprovedForAll(address, address)
        public
        view
        virtual
        override
        returns (bool)
    {
        return true;
    }
}
