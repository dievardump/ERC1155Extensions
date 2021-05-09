//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC1155AfterTransfer.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract ERC1155Enumerable is ERC1155AfterTransfer {
    using EnumerableSet for EnumerableSet.UintSet;
    mapping(address => EnumerableSet.UintSet) internal _accountTokens;

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
        _updateAccountsTokens(from, to, ids);
    }

    /**
     * @dev After any transfer, checks if from and to accountTokens should be updated
     * this function can be very expensive, it reads the storage a lot, be careful why you make use of this.
     *
     * @param from the address that lost tokens
     * @param to the address that fained tokens
     * @param ids the ids that have been transfered
     */
    function _updateAccountsTokens(
        address from,
        address to,
        uint256[] memory ids
    ) internal virtual {
        bool checkAddressFrom = from != address(0);
        bool checkAddressTo = to != address(0);

        for (uint256 i; i < ids.length; i++) {
            // if from has balance 0, remove from accountTokens
            if (checkAddressFrom && balanceOf(from, ids[i]) == 0) {
                _accountTokens[from].remove(ids[i]);
            }

            // here we always have to try to add it if the balance > 0
            // we can not use amounts[i] because a transferBatch could contain
            // twice the same id, and amounts[i] would never match the current balance
            // we still have to check balance though, because transfers can be of 0 (yes...)
            if (checkAddressTo && balanceOf(to, ids[i]) > 0) {
                _accountTokens[to].add(ids[i]);
            }
        }
    }

    /**
     * @dev get the number of different tokens own by an account
     *
     * @param account the account address
     */
    function getAccountTokensCount(address account)
        public
        view
        virtual
        returns (uint256)
    {
        return _accountTokens[account].length();
    }

    /**
     * @dev get the token owned at index {index} of account
     * This is using EnumerableSet so order can change at any time with inserts and removals     *
     *
     * @param account the account address
     * @param index the index in the list
     */
    function getAccountTokensByIndex(address account, uint256 index)
        public
        view
        virtual
        returns (uint256)
    {
        return _accountTokens[account].at(index);
    }

    /**
     * @dev Get a paginated list of an account tokens
     * This is a pretty expensive function and SHOULD be only used externally
     * or if you really know what you're doing.
     *
     * @param account The account we want the list of tokens
     * @param cursor Index to start at
     * @param limit how many we want per page
     *
     * @return tokenIds the token Ids
     * @return amounts the token balances
     * @return nextCursor next cursor to use
     */
    function getAccountTokensPaginated(
        address account,
        uint256 cursor,
        uint256 limit
    )
        external
        view
        virtual
        returns (
            uint256[] memory tokenIds,
            uint256[] memory amounts,
            uint256 nextCursor
        )
    {
        uint256 itemsCount = getAccountTokensCount(account);
        uint256 length = limit;
        if (length > itemsCount - cursor) {
            length = itemsCount - cursor;
        }

        tokenIds = new uint256[](length);
        amounts = new uint256[](length);
        for (uint256 i; i < length; i++) {
            tokenIds[i] = getAccountTokensByIndex(account, cursor + i);
            amounts[i] = balanceOf(account, tokenIds[i]);
        }

        return (tokenIds, amounts, cursor + length);
    }
}
