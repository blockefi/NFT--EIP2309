//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "contracts/upgradeability/CustomOwnable.sol";
import "contracts/interfaces/ICAMAEvents.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract TestCAMA is Context, CustomOwnable, ICAMAEvents, ERC165, IERC721, IERC721Metadata {//change the name at the end
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;

    struct Batch {
        address owner;
        uint96 size;
    }

    // Mapping from batch start Batch
    mapping (uint256 => Batch) private batches;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Mapping owner address to token count
    mapping(address => uint) internal _balances;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    uint256 public constant MAX_SUPPLY = 648000000000000;

    uint128 public batchSize;
    uint128 public nextBatch;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    address _rootNode;

    bool internal _initialized;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function initialize(address owner, uint128 _batchSize, string memory name_, string memory symbol_) public {
        require(!_initialized, "CAMA: Already Initialized");
        _initialized = true;
        _setOwner(owner);
        _rootNode = owner;
        batchSize = _batchSize;
        _name = name_;
        _symbol = symbol_;

        _balances[owner] = MAX_SUPPLY;

        emit ConsecutiveTransfer(0, MAX_SUPPLY, address(0), owner);
    }

     /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(false, "CAMA: This feature will be available soon");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "CAMA: Invalid TokenId");

        if (_owners[tokenId] != address(0)) {
            return _owners[tokenId];
        }

        uint256 start = getBatchStart(tokenId);

        Batch storage batch = batches[start];

        if (batch.size + start > tokenId) {
            return batch.owner;
        }

        return _rootNode;
    }

    function getBatchStart(uint256 tokenId) public view returns (uint256) {
        return tokenId.div(batchSize).mul(batchSize);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "CAMA: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. CAMA will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return MAX_SUPPLY;
    }

    function setBaseURI(string memory uri) public virtual onlyOwner {
        if (bytes(uri).length > 0) {
            _setBaseURI(uri);
        }
    }

    function setTokenURI(uint tokenId, string memory uri) public virtual returns(bool) {
        require(_msgSender() == ownerOf(tokenId), "CAMA: Invalid Token Owner");
        require(bytes(uri).length > 0, "CAMA: Invalid URI");

        _setTokenURI(tokenId, uri);
        return true;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = this.ownerOf(tokenId);
        require(to != owner, "CAMA: approval to current owner");

        require(_msgSender() == owner || this.isApprovedForAll(owner, _msgSender()),
            "CAMA: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "CAMA: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "CAMA: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "CAMA: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function batchTransfer(address to, uint96 size) public virtual {
        require(_msgSender() == owner() || this.isApprovedForAll(_rootNode, _msgSender()), "CAMA: transfer caller is not owner nor approved");
        require(to != _rootNode, "CAMA: Can't transfer batch to own address");
        _batchTransfer(_rootNode, to, size);
    }

    function batchTransferFrom(address from, address to, uint[] memory ids) public virtual {
        require(from == _msgSender() || this.isApprovedForAll(from, _msgSender()), "CAMA: transfer caller is not owner nor approved");
        _batchTransferFrom(from, to, ids);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "CAMA: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * CAMA internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "CAMA: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < MAX_SUPPLY;
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "CAMA: operator query for nonexistent token");
        address owner = this.ownerOf(tokenId);
        return (owner == spender || getApproved(tokenId) == spender || this.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */


    function _burn(uint256 tokenId) internal virtual {
        address owner = this.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

         _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, CAMA imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(this.ownerOf(tokenId) == from, "CAMA: transfer of token that is not own");
        require(to != address(0), "CAMA: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

     function _batchTransfer(address from, address to, uint96 size) internal returns (uint) {
        require(to != address(0), "CAMA: must not be null");
        require(size > 0 && size <= batchSize, "CAMA: size must be within limits");

        uint256 start = nextBatch;
        require(_exists(start.add(size)), "CAMA: Max token limit reached");

        Batch storage batch = batches[start];

        batch.owner = to;
        batch.size = size;

        uint256 end = start.add(size);

        emit ConsecutiveTransfer(start, end, from, to);

        nextBatch = uint128(uint256(nextBatch).add(uint256(batchSize)));
        _balances[from] = _balances[from].sub(size);
        _balances[to] = _balances[to].add(size);
        return start;
    }

    function _batchTransferFrom(address from, address to, uint[] memory ids) internal virtual {
        uint len = ids.length;
        require(to != address(0), "CAMA: must not be null");
        require(ids.length > 1, "CAMA: Min 2 ids");

        for (uint i; i < ids.length; i++) {
            require(_exists(ids[i]), "CAMA: Invalid TokenId");
            require(this.ownerOf(ids[i]) == from, "CAMA: Invalid Owner");
            _beforeTokenTransfer(from, to, ids[i]);

            // Clear approvals from the previous owner
            _approve(address(0), ids[i]);
            _owners[ids[i]] = to;

            emit Transfer(from, to, ids[i]);
        }

        _balances[from] -= len;
        _balances[to] += len;
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "CAMA: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

      /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("CAMA: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(this.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. CAMA includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}