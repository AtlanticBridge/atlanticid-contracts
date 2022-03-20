// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../node_modules/@openzeppelin/contracts/utils/Context.sol";
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "./DateTime.sol";

/**
TODO: Add EVENTS
        EVENT 1] Mint(tokenId)
        EVENT 2]
TODO: Require a signed transaction from the "to" address before minting approval.
 */

contract AtlanticId is
    Context,
    AccessControlEnumerable,
    ERC721Burnable,
    ERC721Enumerable,
    ERC721Pausable
{
    //** LIBRARIES */
    using Counters for Counters.Counter;
    using DateTime for DateTime._DateTime;
    // using DateTime for *;

    /** --- USER ROLES --- */
    bytes32 public constant MINTER_ROLE   = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE   = keccak256("PAUSER_ROLE");
    bytes32 public constant BURNER_ROLE   = keccak256("BURNER_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    /** LOCAL VARIABLES */
    string private key;
    address atlanticIdOwner;
    Counters.Counter private _tokenIdTracker;   // Token Id Tracker
    string private _baseTokenURI;               // This URI should point to the public JSON data of the user
    struct AID {                                // (A)tlantic (Id)entification
        string ens;                               //> | User's name
        string uid;                               //> | User's Identification Number
        string exchange;                          //> | Centralized Exchange where user's KYC info is registered
        uint256 tokenId;                          //> | User's NFT token ID.
        DateTime._DateTime expiry;                //> | Expiration date - period of valid ID
    }
    mapping(uint256 => AID) id_to_AID;          // TokenId mapped to User's Information
    mapping(address => string) mint_key;        // Checks if address has an approved key.
    mapping(address => bool) transfer_key;      // Checks if address has an approved key.
    mapping(string => uint) _months;            // Mapping of months to numbers

    /** EVENTS */
    event Mint(uint256 tokenId, uint timestamp, uint256 yearExpired);


    /** CONSTRUCTOR */
    constructor() ERC721("AtlanticId","AID") {
        atlanticIdOwner = _msgSender();
        // --- SET ROLES ---
        _setupRole(MINTER_ROLE, atlanticIdOwner);
        _setupRole(PAUSER_ROLE, atlanticIdOwner);
        _setupRole(BURNER_ROLE, atlanticIdOwner);
        _setupRole(TRANSFER_ROLE, atlanticIdOwner);
    }

    // ===================================================
    /** --- ERC-721 FUNCTIONS OVERRIDE & INITIALIZE --- */
    // ===================================================
    /**
    FUNCTIONS
    ---------
        > _baseURI()
        > supportsInterface()
        > unpause()
        > _beforeTokenTransfer()
        > _beforeTokenTransfer()
        > transferFrom()
        > safeTransferFrom()
    
    TRANSFER FUNCTIONS
    ------------------
        > 
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override canTransfer(_msgSender())
    {
        _transfer(from, to, tokenId);
        delete transfer_key[_msgSender()];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override canTransfer(_msgSender())
    {
        _safeTransfer(from, to, tokenId, _data);
        delete transfer_key[_msgSender()];
    }

    // ==============================
    /** ATLANTICID SPECIFIC FUNCTIONS */
    /**
    FUNCTIONS
    ---------
        > approveMint()
        > approveTransfer()
        > mint()
     */

    function approveMint(string memory _key, address to) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721ApprovedMint: must have MINTER_ROLE or be owner to allow minting.");
        mint_key[to] = _key;
    }

    function getMintKey(address to) public view returns (string memory) {
        require(_msgSender() == atlanticIdOwner, "ERC721GetMintKey: must be the owner of the contract to retrieve mint key.");
        return mint_key[to];
    }

    function approveTransfer(address to) public {
        require(hasRole(TRANSFER_ROLE, _msgSender()), "ERC721ApprovedTransfer: must have TRANSFER_ROLE or be owner to allow transfer.");
        transfer_key[to] = true;
    }

    function getTransferKey(address from) public view returns (bool) {
        require(_msgSender() == atlanticIdOwner, "ERC721GetTransferKey: must be the owner of the contract to retrieve transfer key");
        return transfer_key[from];
    }


    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     *
     *
     * TODO: 
     *  - Add approved wallet access by contract owner.
     */
    function mint(
        string memory _ens,
        string memory _uid,
        string memory _exchange,
        string memory _key
    ) public
      hasKey(_msgSender(), _key)
    {
        /** FUNCTION VARIABLES */
        uint _timestamp = block.timestamp;
        // STEP 1: Require MINTER_ROLE & _key
        // require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");
        uint256 _tokenId = _tokenIdTracker.current();

        // STEP 2: Calculate the Expiration Date
        // --- Calculate the Expiration Date ---
        DateTime._DateTime memory _expiry = DateTime.parseTimestamp(_timestamp);
        _expiry.year = _expiry.year + 1;

        // STEP 3: Create Mapping
        // --- Map the NFT IdNumber to the Data --- 
        id_to_AID[_tokenIdTracker.current()] = AID({
            ens: _ens,
            uid: _uid,
            exchange: _exchange,
            expiry: _expiry,
            tokenId: _tokenId
        });

        // STEP 4: Mint NFID
        _safeMint(_msgSender(), _tokenId);

        // SETUP 5: Allow atlanticIdOwner to Manage NFT
        approve(atlanticIdOwner, _tokenId);
        emit Mint(_tokenId, _timestamp, _expiry.year);
        _tokenIdTracker.increment();

        // STEP 6: Delete _key
        delete mint_key[_msgSender()];
    }


    /**
        ==============================
        |   NFID SPECIFIC FUNTIONS   |
        ==============================
        TODO: Add isValidAid()  - This function could use Chainlink (recommended) to bring in the current date, 
                                  or the function could take in what the current date it is (not recommended).
        TODO: Add getUid()      - Returns AID user ID.
        TODO: Add getEns()
        TODO: Add getExchange()
        TODO: Add getExpry()
     */

    function getUid(
        uint256 _tokenId
    ) public view
      returns (string memory)
    {
        require(_exists(_tokenId),"ERC721: tokenId does not exist.");
        return id_to_AID[_tokenId].uid;
    }

    function getEns(
        uint256 _tokenId
    ) public view 
      returns (string memory)
    {
        require(_exists(_tokenId),"ERC721: tokenId does not exist.");
        require(keccak256(abi.encodePacked(_msgSender())) == keccak256(abi.encodePacked(atlanticIdOwner)),"ERC721: ");
        return id_to_AID[_tokenId].ens;
    }

    function getExchange(
        uint256 _tokenId
    ) public view
      returns (string memory)
    {
        require(_exists(_tokenId),"ERC721: tokenId does not exist.");
        return id_to_AID[_tokenId].exchange;
    }

    function getExpry(
        uint256 _tokenId
    ) public view
      returns (uint8 day, uint8 month, uint16 year)
    {
        require(_exists(_tokenId),"ERC721: tokenId does not exist.");
        AID memory user_aid = id_to_AID[_tokenId];
        DateTime._DateTime memory user_date = user_aid.expiry;
        return (user_date.day, user_date.month, user_date.year);
    }

    function isValidAid(
        uint256 _tokenId
    ) public view
      returns (bool)
    {
        require(_exists(_tokenId),"ERC721: tokenId does not exist.");
        uint16 now_year = DateTime.getYear(block.timestamp);
        uint8 now_month = DateTime.getMonth(block.timestamp);
        uint8 now_day = DateTime.getDay(block.timestamp);

        AID memory user_aid = id_to_AID[_tokenId];
        DateTime._DateTime memory user_date = user_aid.expiry;
        uint16 id_year = user_date.year;
        uint8 id_month = user_date.month;
        uint8 id_day = user_date.day;

        if (id_year < now_year) {
            return true;
        } else if (id_year > now_year) {
            return false;
        } else {
            if (now_month < id_month) {
                return true;
            } else if (now_month > id_month) {
                return false;
            } else {
                if (now_day < id_day) {
                    return true;
                } else {
                    return false;
                }
            }
        }
    }

    // function _transferExists(address from) internal view virtual returns (bool) {
    //     return transfer_key[from] == true;
    // }

    // function _mintExists(address from) internal view virtual returns (bool) {
    //     return mint_key[from] != "";
    // }

    /** MODIFIERS */
    // keccak256(abi.encodePacked(a)
    modifier hasKey(address _sender, string memory _key) {
      if (keccak256(abi.encodePacked(mint_key[_sender])) == keccak256(abi.encodePacked(_key))) {
         _;
      } else {
          revert("Account (msg.sender) must have an approved mint key.");
      }
    }

    modifier canTransfer(address _sender) {
      if (transfer_key[_sender]) {
         _;
      } else {
          revert("Account (msg.sender) must have an approved transfer key.");
      }
    }

}