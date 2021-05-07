//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract ERC1155Enumerable is ERC1155 {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(address => EnumerableSet.UintSet) private _accountTokens;

    /**
     * @dev After any transfer, checks if from and to accountTokens should be updated
     *
     * @param from the address that lost tokens
     * @param to the address that fained tokens
     * @param ids the ids that have been transfered
     */
    function _updateAccountsTokens(
        address from,
        address to,
        uint256[] memory ids
    ) internal {
        bool checkAddressFrom = from != address(0);
        bool checkAddressTo = to != address(0);

        for (uint256 i; i < ids.length; i++) {
            // if from has balance 0, remove from accountTokens
            if (checkAddressFrom && balanceOf(from, ids[i]) == 0) {
                _accountTokens[from].remove(ids[i]);
            }

            // here we always have to try to add it if the balance > 0
            // we can not use amounts[i] because a transferBatch could contain
            // twice the same id, and amounts[i] would match for none of them
            // we still have to check balance though, because transfers can be of 0 (yes...)
            if (checkAddressTo && balanceOf(to, ids[i]) > 0) {
                _accountTokens[to].add(ids[i]);
            }
        }
    }

    /**
     * @dev Two getters - can be removed if we don't want enumeration public
     * but it helps in tests
     */
    function getAccountTokensNumber(address account)
        external
        view
        returns (uint256)
    {
        return _accountTokens[account].length();
    }

    function getAccountTokensByIndex(address account, uint256 index)
        external
        view
        returns (uint256)
    {
        return _accountTokens[account].at(index);
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        super._mint(account, id, amount, data);
        _updateAccountsTokens(
            address(0),
            account,
            _asSingletonArrayEnumerable(id)
        );
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._mintBatch(to, ids, amounts, data);
        _updateAccountsTokens(address(0), to, ids);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        super.safeTransferFrom(from, to, id, amount, data);

        _updateAccountsTokens(from, to, _asSingletonArrayEnumerable(id));
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);

        _updateAccountsTokens(from, to, ids);
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        super._burn(account, id, amount);
        _updateAccountsTokens(
            account,
            address(0),
            _asSingletonArrayEnumerable(id)
        );
    }

    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        super._burnBatch(account, ids, amounts);
        _updateAccountsTokens(account, address(0), ids);
    }

    // needs to give this name because solidity compilers thinks
    // I want to override function from parent
    function _asSingletonArrayEnumerable(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}
