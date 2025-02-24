// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
pragma abicoder v2;

import "./NFTStorage.sol";

import "./NFTState.sol";
import "./NFTView.sol";
//import "hardhat/console.sol";
/**
*****************
TEMPLATE CONTRACT
*****************

Although this code is available for viewing on GitHub and Etherscan, the general public is NOT given a license to freely deploy smart contracts based on this code, on any blockchains.

To prevent confusion and increase trust in the audited code bases of smart contracts we produce, we intend for there to be only ONE official Factory address on the blockchain producing the corresponding smart contracts, and we are going to point a blockchain domain name at it.

Copyright (c) Intercoin Inc. All rights reserved.

ALLOWED USAGE.

Provided they agree to all the conditions of this Agreement listed below, anyone is welcome to interact with the official Factory Contract at the this address to produce smart contract instances, or to interact with instances produced in this manner by others.

Any user of software powered by this code MUST agree to the following, in order to use it. If you do not agree, refrain from using the software:

DISCLAIMERS AND DISCLOSURES.

Customer expressly recognizes that nearly any software may contain unforeseen bugs or other defects, due to the nature of software development. Moreover, because of the immutable nature of smart contracts, any such defects will persist in the software once it is deployed onto the blockchain. Customer therefore expressly acknowledges that any responsibility to obtain outside audits and analysis of any software produced by Developer rests solely with Customer.

Customer understands and acknowledges that the Software is being delivered as-is, and may contain potential defects. While Developer and its staff and partners have exercised care and best efforts in an attempt to produce solid, working software products, Developer EXPRESSLY DISCLAIMS MAKING ANY GUARANTEES, REPRESENTATIONS OR WARRANTIES, EXPRESS OR IMPLIED, ABOUT THE FITNESS OF THE SOFTWARE, INCLUDING LACK OF DEFECTS, MERCHANTABILITY OR SUITABILITY FOR A PARTICULAR PURPOSE.

Customer agrees that neither Developer nor any other party has made any representations or warranties, nor has the Customer relied on any representations or warranties, express or implied, including any implied warranty of merchantability or fitness for any particular purpose with respect to the Software. Customer acknowledges that no affirmation of fact or statement (whether written or oral) made by Developer, its representatives, or any other party outside of this Agreement with respect to the Software shall be deemed to create any express or implied warranty on the part of Developer or its representatives.

INDEMNIFICATION.

Customer agrees to indemnify, defend and hold Developer and its officers, directors, employees, agents and contractors harmless from any loss, cost, expense (including attorney’s fees and expenses), associated with or related to any demand, claim, liability, damages or cause of action of any kind or character (collectively referred to as “claim”), in any manner arising out of or relating to any third party demand, dispute, mediation, arbitration, litigation, or any violation or breach of any provision of this Agreement by Customer.

NO WARRANTY.

THE SOFTWARE IS PROVIDED “AS IS” WITHOUT WARRANTY. DEVELOPER SHALL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL, INCIDENTAL, CONSEQUENTIAL, OR EXEMPLARY DAMAGES FOR BREACH OF THE LIMITED WARRANTY. TO THE MAXIMUM EXTENT PERMITTED BY LAW, DEVELOPER EXPRESSLY DISCLAIMS, AND CUSTOMER EXPRESSLY WAIVES, ALL OTHER WARRANTIES, WHETHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT LIMITATION ALL IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR USE, OR ANY WARRANTY ARISING OUT OF ANY PROPOSAL, SPECIFICATION, OR SAMPLE, AS WELL AS ANY WARRANTIES THAT THE SOFTWARE (OR ANY ELEMENTS THEREOF) WILL ACHIEVE A PARTICULAR RESULT, OR WILL BE UNINTERRUPTED OR ERROR-FREE. THE TERM OF ANY IMPLIED WARRANTIES THAT CANNOT BE DISCLAIMED UNDER APPLICABLE LAW SHALL BE LIMITED TO THE DURATION OF THE FOREGOING EXPRESS WARRANTY PERIOD. SOME STATES DO NOT ALLOW THE EXCLUSION OF IMPLIED WARRANTIES AND/OR DO NOT ALLOW LIMITATIONS ON THE AMOUNT OF TIME AN IMPLIED WARRANTY LASTS, SO THE ABOVE LIMITATIONS MAY NOT APPLY TO CUSTOMER. THIS LIMITED WARRANTY GIVES CUSTOMER SPECIFIC LEGAL RIGHTS. CUSTOMER MAY HAVE OTHER RIGHTS WHICH VARY FROM STATE TO STATE. 

LIMITATION OF LIABILITY. 

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL DEVELOPER BE LIABLE UNDER ANY THEORY OF LIABILITY FOR ANY CONSEQUENTIAL, INDIRECT, INCIDENTAL, SPECIAL, PUNITIVE OR EXEMPLARY DAMAGES OF ANY KIND, INCLUDING, WITHOUT LIMITATION, DAMAGES ARISING FROM LOSS OF PROFITS, REVENUE, DATA OR USE, OR FROM INTERRUPTED COMMUNICATIONS OR DAMAGED DATA, OR FROM ANY DEFECT OR ERROR OR IN CONNECTION WITH CUSTOMER'S ACQUISITION OF SUBSTITUTE GOODS OR SERVICES OR MALFUNCTION OF THE SOFTWARE, OR ANY SUCH DAMAGES ARISING FROM BREACH OF CONTRACT OR WARRANTY OR FROM NEGLIGENCE OR STRICT LIABILITY, EVEN IF DEVELOPER OR ANY OTHER PERSON HAS BEEN ADVISED OR SHOULD KNOW OF THE POSSIBILITY OF SUCH DAMAGES, AND NOTWITHSTANDING THE FAILURE OF ANY REMEDY TO ACHIEVE ITS INTENDED PURPOSE. WITHOUT LIMITING THE FOREGOING OR ANY OTHER LIMITATION OF LIABILITY HEREIN, REGARDLESS OF THE FORM OF ACTION, WHETHER FOR BREACH OF CONTRACT, WARRANTY, NEGLIGENCE, STRICT LIABILITY IN TORT OR OTHERWISE, CUSTOMER'S EXCLUSIVE REMEDY AND THE TOTAL LIABILITY OF DEVELOPER OR ANY SUPPLIER OF SERVICES TO DEVELOPER FOR ANY CLAIMS ARISING IN ANY WAY IN CONNECTION WITH OR RELATED TO THIS AGREEMENT, THE SOFTWARE, FOR ANY CAUSE WHATSOEVER, SHALL NOT EXCEED 1,000 USD.

TRADEMARKS.

This Agreement does not grant you any right in any trademark or logo of Developer or its affiliates.

LINK REQUIREMENTS.

Operators of any Websites and Apps which make use of smart contracts based on this code must conspicuously include the following phrase in their website, featuring a clickable link that takes users to intercoin.app:
"Visit https://intercoin.app to launch your own NFTs, DAOs and other Web3 solutions."

STAKING OR SPENDING REQUIREMENTS.

In the future, Developer may begin requiring staking or spending of Intercoin tokens in order to take further actions (such as producing series and minting tokens). Any staking or spending requirements will first be announced on Developer's website (intercoin.org) four weeks in advance. Staking requirements will not apply to any actions already taken before they are put in place.

CUSTOM ARRANGEMENTS.

Reach out to us at intercoin.org if you are looking to obtain Intercoin tokens in bulk, remove link requirements forever, remove staking requirements forever, or get custom work done with your Web3 projects.

ENTIRE AGREEMENT

This Agreement contains the entire agreement and understanding among the parties hereto with respect to the subject matter hereof, and supersedes all prior and contemporaneous agreements, understandings, inducements and conditions, express or implied, oral or written, of any nature whatsoever with respect to the subject matter hereof. The express terms hereof control and supersede any course of performance and/or usage of the trade inconsistent with any of the terms hereof. Provisions from previous Agreements executed between Customer and Developer., which are not expressly dealt with in this Agreement, will remain in effect.

SUCCESSORS AND ASSIGNS

This Agreement shall continue to apply to any successors or assigns of either party, or any corporation or other entity acquiring all or substantially all the assets and business of either party whether by operation of law or otherwise.

ARBITRATION

All disputes related to this agreement shall be governed by and interpreted in accordance with the laws of New York, without regard to principles of conflict of laws. The parties to this agreement will submit all disputes arising under this agreement to arbitration in New York City, New York before a single arbitrator of the American Arbitration Association (“AAA”). The arbitrator shall be selected by application of the rules of the AAA, or by mutual agreement of the parties, except that such arbitrator shall be an attorney admitted to practice law New York. No party to this agreement will challenge the jurisdiction or venue provisions as provided in this section. No party to this agreement will challenge the jurisdiction or venue provisions as provided in this section.
**/
contract NFTMain is NFTStorage {
    
    NFTState implNFTState;
    NFTView implNFTView;

    /**
    * @notice initializes contract
    */
    function initialize(
        address implNFTState_,
        address implNFTView_,
        string memory name_, 
        string memory symbol_, 
        string memory contractURI_, 
        string memory baseURI_, 
        string memory suffixURI_, 
        address costManager_,
        address producedBy_
    ) 
        public 
        //override
        initializer 
    {
        implNFTState = NFTState(implNFTState_);
        implNFTView = NFTView(implNFTView_);

        _functionDelegateCall(
            address(implNFTState), 
            abi.encodeWithSelector(
                NFTState.initialize.selector,
                name_, symbol_, contractURI_, baseURI_, suffixURI_, costManager_, producedBy_
            )
            //msg.data
        );

    }

    /**
    * @param baseURI_ baseURI
    * @custom:calledby owner
    * @custom:shortd set default baseURI
    */
    function setBaseURI(
        string calldata baseURI_
    ) 
        external
    {
        requireOnlyOwner();
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.setBaseURI.selector,
            //     baseURI_
            // )
            msg.data
        );

    }
    
    /**
    * @dev sets the default URI suffix for the whole contract
    * @param suffix_ the suffix to append to URIs
    * @custom:calledby owner
    * @custom:shortd set default suffix
    */
    function setSuffix(
        string calldata suffix_
    ) 
        external
    {
        requireOnlyOwner();
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.setSuffix.selector,
            //     suffix_
            // )
            msg.data
        );
    }

    /**
    * @dev sets contract URI. 
    * @param newContractURI new contract URI
    * @custom:calledby owner
    * @custom:shortd set default contract URI
    */
    function setContractURI(
        string memory newContractURI
    ) 
        external 
    {
        requireOnlyOwner();
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.setContractURI.selector,
            //     newContractURI
            // )
            msg.data
        );

    }

    /**
    * @dev sets information for series with 'seriesId'. 
    * @param seriesId series ID
    * @param info new info to set
    * @custom:calledby owner or series author
    * @custom:shortd set series Info
    */
    function setSeriesInfo(
        uint64 seriesId, 
        SeriesInfo memory info 
    ) 
        external
    {
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.setSeriesInfo.selector,
            //     seriesId, info
            // )
            msg.data
        );

    }
    /**
    * @dev sets information for series with 'seriesId'. 
    * @param seriesId series ID
    * @param info new info to set
    * @custom:calledby owner or series author
    * @custom:shortd set series Info
    */
    function setSeriesInfo(
        uint64 seriesId, 
        SeriesInfo memory info,
        CommunitySettings memory transferWhitelistSettings,
        CommunitySettings memory buyWhitelistSettings
    ) 
        external
    {
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.setSeriesInfo.selector,
            //     seriesId, info
            // )
            msg.data
        );

    }

    /**
    * set commission paid to contract owner
    * @param commission new commission info
    * @custom:calledby owner
    * @custom:shortd set owner commission
    */
    function setOwnerCommission(
        CommissionInfo memory commission
    ) 
        external 
    {
        requireOnlyOwner();
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.setOwnerCommission.selector,
            //     commission
            // )
            msg.data
        );
    }

    /**
    * @dev set commission for series
    * @param seriesId seriesId
    * @param commissionData new commission data
    * @custom:calledby owner or series author
    * @custom:shortd set new commission
    */
    function setCommission(
        uint64 seriesId, 
        CommissionData memory commissionData
    ) 
        external 
    {
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.setCommission.selector,
            //     seriesId, commissionData
            // )
            msg.data
        );
    }

    /**
    * clear commission for series
    * @param seriesId seriesId
    * @custom:calledby owner or series author
    * @custom:shortd remove commission
    */
    function removeCommission(
        uint64 seriesId
    ) 
        external 
    {
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.removeCommission.selector,
            //     seriesId
            // )
            msg.data
        );
        
    }

    /**
    * @dev lists on sale NFT with defined token ID with specified terms of sale
    * @param tokenId token ID
    * @param price price for sale 
    * @param currency currency of sale 
    * @param duration duration of sale 
    * @custom:calledby token owner
    * @custom:shortd list on sale
    */
    function listForSale(
        uint256 tokenId,
        uint256 price,
        address currency,
        uint64 duration
    )
        external 
    {
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.listForSale.selector,
            //     tokenId, price, currency, duration
            // )
            msg.data
        );

    }
    
    /**
    * @dev removes from sale NFT with defined token ID
    * @param tokenId token ID
    * @custom:calledby token owner
    * @custom:shortd remove from sale
    */
    function removeFromSale(
        uint256 tokenId
    )
        external 
    {
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.removeFromSale.selector,
            //     tokenId
            // )
            msg.data
        );

    }

    
    /**
    * @dev mints and distributes NFTs with specified IDs
    * to specified addresses
    * @param tokenIds list of NFT IDs to be minted
    * @param addresses list of receiver addresses
    * @custom:calledby owner or series author
    * @custom:shortd mint and distribute new tokens
    */
    function mintAndDistribute(
        uint256[] memory tokenIds, 
        address[] memory addresses
    )
        external 
    {
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.mintAndDistribute.selector,
            //     tokenIds, addresses
            // )
            msg.data
        );

    }

    /**
    * @dev mints and distributes `amount` NFTs by `seriesId` to `account`
    * @param seriesId seriesId
    * @param account receiver addresses
    * @param amount amount of tokens
    * @custom:calledby owner or series author
    * @custom:shortd mint and distribute new tokens
    */
    function mintAndDistributeAuto(
        uint64 seriesId, 
        address account,
        uint256 amount
    )
        external
    {
        _functionDelegateCall(address(implNFTState), msg.data);
    }
    
    /** 
    * @dev sets the utility token
    * @param costManager_ new address of utility token, or 0
    * @custom:calledby owner or factory that produced instance
    * @custom:shortd set cost manager address
    */
    // function overrideCostManager(
    //     address costManager_
    // ) 
    //     external 
        
    // {

    //     _functionDelegateCall(
    //         address(implNFTState), 
    //         // abi.encodeWithSelector(
    //         //     NFTState.overrideCostManager.selector,
    //         //     costManager_
    //         // )
    //         msg.data
    //     );

    // }

    ///////////////////////////////////////
    //// external view section ////////////
    ///////////////////////////////////////


    /**
    * @dev returns the list of all NFTs owned by 'account' with limit
    * @param account address of account
    * @custom:calledby everyone
    * @custom:shortd returns the list of all NFTs owned by 'account' with limit
    */
    function tokensByOwner(
        address account,
        uint32 limit
    ) 
        external
        view
        returns (uint256[] memory ret)
    {
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.tokensByOwner.selector, 
                    account, limit
                ), 
                ""
            ), 
            (uint256[])
        );

    }

    /**
    * @dev returns the list of hooks for series with `seriesId`
    * @param seriesId series ID
    * @custom:calledby everyone
    * @custom:shortd returns the list of hooks for series
    */
    function getHookList(
        uint64 seriesId
    ) 
        external 
        view 
        returns(address[] memory) 
    {
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.getHookList.selector, 
                    seriesId
                ), 
                ""
            ), 
            (address[])
        );

    }

    /********************************************************************
    ****** public section ***********************************************
    *********************************************************************/
    function buy(
        uint256[] memory tokenIds,
        address currency,
        uint256 totalPrice,
        bool safe,
        uint256 hookCount,
        address buyFor
    ) 
        public 
        virtual
        payable 
        nonReentrant 
    {
        _functionDelegateCall(address(implNFTState), msg.data);
    }

    /**
    * @dev buys NFT for native coin with undefined id. 
    * Id will be generate as usually by auto inrement but belong to seriesId
    * and transfer token if it is on sale
    * @param seriesId series ID whene we can find free token to buy
    * @param price amount of specified native coin to pay
    * @param safe use safeMint and safeTransfer or not, 
    * @param hookCount number of hooks 
    * @custom:calledby everyone
    * @custom:shortd buys NFT for native coin
    */
    function buyAuto(
        uint64 seriesId, 
        uint256 price, 
        bool safe, 
        uint256 hookCount
    ) 
        public 
        virtual
        payable 
        nonReentrant 
    {
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     //NFTState.buy.selector,
            //     bytes4(keccak256(bytes("buy(uint256,uint256,bool,uint256)"))),
            //     tokenId, price, safe, hookCount
            // )
            msg.data
        );

    }

    /**
    * @dev buys NFT for native coin with undefined id. 
    * Id will be generate as usually by auto inrement but belong to seriesId
    * and transfer token if it is on sale
    * @param seriesId series ID whene we can find free token to buy
    * @param price amount of specified native coin to pay
    * @param safe use safeMint and safeTransfer or not, 
    * @param hookCount number of hooks 
    * @param buyFor address of new nft owner
    * @custom:calledby everyone
    * @custom:shortd buys NFT for native coin
    */
    function buyAuto(
        uint64 seriesId, 
        uint256 price, 
        bool safe, 
        uint256 hookCount,
        address buyFor
    ) 
        public 
        virtual
        payable 
        nonReentrant 
    {
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     //NFTState.buy.selector,
            //     bytes4(keccak256(bytes("buy(uint256,uint256,bool,uint256)"))),
            //     tokenId, price, safe, hookCount
            // )
            msg.data
        );

    }

    
    /**
    * @dev buys NFT for native coin with undefined id. 
    * Id will be generate as usually by auto inrement but belong to seriesId
    * and transfer token if it is on sale
    * @param seriesId series ID whene we can find free token to buy
    * @param currency address of token to pay with
    * @param price amount of specified token to pay
    * @param safe use safeMint and safeTransfer or not
    * @param hookCount number of hooks 
    * @custom:calledby everyone
    * @custom:shortd buys NFT for specified currency
    */
    function buyAuto(
        uint64 seriesId, 
        address currency, 
        uint256 price, 
        bool safe, 
        uint256 hookCount
    ) 
        public 
        virtual
        nonReentrant 
    {

        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     //NFTState.buy.selector,
            //     bytes4(keccak256(bytes("buy(uint256,address,uint256,bool,uint256)"))),

            //     tokenId, currency, price, safe, hookCount
            // )
            msg.data
        );

    }

    /**
    * @dev buys NFT for native coin with undefined id. 
    * Id will be generate as usually by auto inrement but belong to seriesId
    * and transfer token if it is on sale
    * @param seriesId series ID whene we can find free token to buy
    * @param currency address of token to pay with
    * @param price amount of specified token to pay
    * @param safe use safeMint and safeTransfer or not
    * @param hookCount number of hooks 
    * @param buyFor address of new nft owner
    * @custom:calledby everyone
    * @custom:shortd buys NFT for specified currency
    */
    function buyAuto(
        uint64 seriesId, 
        address currency, 
        uint256 price, 
        bool safe, 
        uint256 hookCount,
        address buyFor
    ) 
        public 
        virtual
        nonReentrant 
    {

        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     //NFTState.buy.selector,
            //     bytes4(keccak256(bytes("buy(uint256,address,uint256,bool,uint256)"))),

            //     tokenId, currency, price, safe, hookCount
            // )
            msg.data
        );

    }


    /** 
    * @dev sets name and symbol for contract
    * @param newName new name 
    * @param newSymbol new symbol 
    * @custom:calledby owner
    * @custom:shortd sets name and symbol for contract
    */
    function setNameAndSymbol(
        string memory newName, 
        string memory newSymbol
    ) 
        public 
    {
        requireOnlyOwner();
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.setNameAndSymbol.selector,
            //     newName, newSymbol
            // )
            msg.data
        );

    }
    
  
    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     *
     * @custom:calledby token owner 
     * @custom:shortd part of ERC721
     */
    function approve(address to, uint256 tokenId) public virtual override {
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.approve.selector,
            //     to, tokenId
            // )
            msg.data
        );

    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     *
     * @custom:calledby token owner 
     * @custom:shortd part of ERC721
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.setApprovalForAll.selector,
            //     operator, approved
            // )
            msg.data
        );

    }
    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     *
     * @custom:calledby token owner 
     * @custom:shortd part of ERC721
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.transferFrom.selector,
            //     from, to, tokenId
            // )
            msg.data
        );

    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     *
     * @custom:calledby token owner 
     * @custom:shortd part of ERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     //NFTState.safeTransferFrom.selector,
            //     bytes4(keccak256(bytes("safeTransferFrom(address,address,uint256,bytes)"))),
            //     from, to, tokenId, ""
            // )
            msg.data
        );

    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     *
     * @custom:calledby token owner 
     * @custom:shortd part of ERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     //NFTState.safeTransferFrom.selector,
            //     bytes4(keccak256(bytes("safeTransferFrom(address,address,uint256,bytes)"))),
            //     from, to, tokenId, _data
            // )
            msg.data
        );

    }

    /**
     * @dev Transfers `tokenId` token from sender to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by sender.
     *
     * Emits a {Transfer} event.
     *
     * @custom:calledby token owner 
     * @custom:shortd part of ERC721
     */
    function transfer(
        address to,
        uint256 tokenId
    ) public virtual {
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.transfer.selector,
            //     to, tokenId
            // )
            msg.data
        );

    }

    /**
     * @dev Safely transfers `tokenId` token from sender to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by sender.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     *
     * @custom:calledby token owner 
     * @custom:shortd part of ERC721
     */
    function safeTransfer(
        address to,
        uint256 tokenId
    ) public virtual override {
        
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.safeTransfer.selector,
            //     to, tokenId
            // )
            msg.data
        );
        
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-burn}.
     * @param tokenId tokenId
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     *
     * @custom:calledby token owner 
     * @custom:shortd part of ERC721
     */
    function burn(uint256 tokenId) public virtual {
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.burn.selector,
            //     tokenId
            // )
            msg.data
        );

    }

    /**
    * @dev the owner should be absolutely sure they trust the trustedForwarder
    * @param trustedForwarder_ must be a smart contract that was audited
    *
    * @custom:calledby owner 
    * @custom:shortd set trustedForwarder address 
    */
    function setTrustedForwarder(
        address trustedForwarder_
    )
        public 
        override
    {
        requireOnlyOwner();
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.setTrustedForwarder.selector,
            //     trustedForwarder_
            // )
            msg.data
        );

    }

    /**
    * @dev link safeHook contract to certain series
    * @param seriesId series ID
    * @param contractAddress address of SafeHook contract
    * @custom:calledby owner 
    * @custom:shortd link safeHook contract to series
    */
    function pushTokenTransferHook(
        uint64 seriesId, 
        address contractAddress
    )
        public 
    {
        requireOnlyOwner();
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.pushTokenTransferHook.selector,
            //     seriesId, contractAddress
            // )
            msg.data
        );

    }

    /**
    * @dev hold baseURI and suffix as values as in current series that token belong
    * @param tokenId token ID to freeze
    * @custom:calledby token owner 
    * @custom:shortd hold series URI and suffix for token
    */
    function freeze(
        uint256 tokenId
    ) 
        public 
    {
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     //NFTState.freeze.selector,
            //     bytes4(keccak256(bytes("freeze(uint256)"))),
            //     tokenId
            // )
            msg.data
        );

    }

    /**
    * @dev hold baseURI and suffix as values baseURI_ and suffix_
    * @param tokenId token ID to freeze
    * @param baseURI_ baseURI to hold
    * @param suffix_ suffixto hold
    * @custom:calledby token owner 
    * @custom:shortd hold URI and suffix for token
    */
    function freeze(
        uint256 tokenId, 
        string memory baseURI_, 
        string memory suffix_
    ) 
        public 
    {
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     //NFTState.freeze.selector,
            //     bytes4(keccak256(bytes("freeze(uint256,string,string)"))),
            //     tokenId, baseURI_, suffix_
            // )
            msg.data
        );
        
    }

    /**
    * @dev unhold token
    * @param tokenId token ID to unhold
    * @custom:calledby token owner 
    * @custom:shortd unhold URI and suffix for token
    */
    function unfreeze(
        uint256 tokenId
    ) 
        public 
    {
        _functionDelegateCall(
            address(implNFTState), 
            // abi.encodeWithSelector(
            //     NFTState.unfreeze.selector,
            //     tokenId
            // )
            msg.data
        );
    }
      

    ///////////////////////////////////////
    //// public view section //////////////
    ///////////////////////////////////////

    function getSeriesInfo(
        uint64 seriesId
    ) 
        public 
        view 
        returns (
            address payable author,
            uint32 limit,
            //SaleInfo saleInfo;
            uint64 onSaleUntil,
            address currency,
            uint256 price,
            ////
            //CommissionData commission;
            uint64 value,
            address recipient,
            /////
            string memory baseURI,
            string memory suffix
        ) 
    {
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.getSeriesInfo.selector, 
                    seriesId
                ), 
                ""
            ), 
            (address,uint32,uint64,address,uint256,uint64,address,string,string)
        );

    }
    /**
    * @dev tells the caller whether they can set info for a series,
    * manage amount of commissions for the series,
    * mint and distribute tokens from it, etc.
    * @param account address to check
    * @param seriesId the id of the series being asked about
    * @custom:calledby everyone
    * @custom:shortd tells the caller whether they can manage a series
    */
    function canManageSeries(address account, uint64 seriesId) public view returns (bool) {
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.canManageSeries.selector, 
                    account, 
                    seriesId
                ), 
                ""
            ), 
            (bool)
        );

    }

    /**
    * @dev tells the caller whether they can transfer an existing token,
    * list it for sale and remove it from sale.
    * Tokens can be managed by their owner
    * or approved accounts via {approve} or {setApprovalForAll}.
    * @param account address to check
    * @param tokenId the id of the tokens being asked about
    * @custom:calledby everyone
    * @custom:shortd tells the caller whether they can transfer an existing token
    */
    function canManageToken(address account, uint256 tokenId) public view returns (bool) {
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.canManageToken.selector, 
                    account,
                    tokenId
                ), 
                ""
            ), 
            (bool)
        );
        
    }

    /**
     * @dev Returns whether `tokenId` exists.
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     * @custom:calledby everyone
     * @custom:shortd returns whether `tokenId` exists.
     */
    function tokenExists(uint256 tokenId) public view virtual returns (bool) {
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.tokenExists.selector, 
                    tokenId
                ), 
                ""
            ), 
            (bool)
        );
    }

    /**
    * @dev returns contract URI. 
    * @custom:calledby everyone
    * @custom:shortd return contract uri
    */
    function contractURI() public view returns(string memory){
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.contractURI.selector
                ), 
                ""
            ), 
            (string)
        );
    }

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     * @custom:calledby everyone
     * @custom:shortd token of owner by index
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.tokenOfOwnerByIndex.selector, 
                    owner, index
                ), 
                ""
            ), 
            (uint256)
        );
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * @custom:calledby everyone
     * @custom:shortd totalsupply
     */
    function totalSupply() public view virtual override returns (uint256) {
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.totalSupply.selector
                ), 
                ""
            ), 
            (uint256)
        );
    }

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     * @custom:calledby everyone
     * @custom:shortd token by index
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.tokenByIndex.selector, 
                    index
                ), 
                ""
            ), 
            (uint256)
        );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     * @custom:calledby everyone
     * @custom:shortd see {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override /*override(ERC165Upgradeable, IERC165Upgradeable)*/ returns (bool) {
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.supportsInterface.selector, 
                    interfaceId
                ), 
                ""
            ), 
            (bool)
        );
      
    }

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     * @custom:calledby everyone
     * @custom:shortd owner balance
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.balanceOf.selector, 
                    owner
                ), 
                ""
            ), 
            (uint256)
        );
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * @custom:calledby everyone
     * @custom:shortd owner address by token id
     */

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.ownerOf.selector, 
                    tokenId
                ), 
                ""
            ), 
            (address)
        );
    }

    /**
     * @dev Returns the token collection name.
     * @custom:calledby everyone
     * @custom:shortd token's name
     */
    function name() public view virtual override returns (string memory) {
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.name.selector
                ), 
                ""
            ), 
            (string)
        );
    }

    /**
     * @dev Returns the token collection symbol.
     * @custom:calledby everyone
     * @custom:shortd token's symbol
     */
    function symbol() public view virtual override returns (string memory) {
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.symbol.selector
                ), 
                ""
            ), 
            (string)
        );
    }

   
    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @param tokenId token id
     * @custom:calledby everyone
     * @custom:shortd return token's URI
     */
    function tokenURI(
        uint256 tokenId
    ) 
        public 
        view 
        virtual 
        override
        returns (string memory) 
    {
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.tokenURI.selector,
                    tokenId
                ), 
                ""
            ), 
            (string)
        );

    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * @custom:calledby everyone
     * @custom:shortd account approved for `tokenId` token
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.getApproved.selector,
                    tokenId
                ), 
                ""
            ), 
            (address)
        );
    }


 

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     * @custom:calledby everyone
     * @custom:shortd see {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.isApprovedForAll.selector,
                    owner, operator
                ), 
                ""
            ), 
            (bool)
        );
    }


    /**
    * @dev returns if token is on sale or not, 
    * whether it exists or not,
    * as well as data about the sale and its owner
    * @param tokenId token ID 
    * @custom:calledby everyone
    * @custom:shortd return token's sale info
    */
    function getTokenSaleInfo(uint256 tokenId) 
        public 
        view 
        returns
        (
            bool isOnSale,
            bool exists, 
            SaleInfo memory data,
            address owner
        ) 
    {
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.getTokenSaleInfo.selector,
                    tokenId
                ), 
                ""
            ), 
            (bool, bool, SaleInfo, address)
        );  
    }

    /**
    * @dev returns info for token and series that belong to
    * @param tokenId token ID 
    * @custom:calledby everyone
    * @custom:shortd full info by token id
    */
    function tokenInfo(
        uint256 tokenId
    )
        public 
        view
        returns(TokenData memory )
    {
        return abi.decode(
            _functionDelegateCallView(
                address(implNFTView), 
                abi.encodeWithSelector(
                    NFTView.tokenInfo.selector,
                    tokenId
                ), 
                ""
            ), 
            (TokenData)
        );  

    }
     
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        //require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    function _functionDelegateCallView(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        //require(isContract(target), "Address: static call to non-contract");
        data = abi.encodePacked(target,data,msg.sender);    
        (bool success, bytes memory returndata) = address(this).staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    fallback() external {
        
        if (msg.sender == address(this)) {

            address implementationLogic;
            
            bytes memory msgData = msg.data;
            bytes memory msgDataPure;
            uint256 offsetnew;
            uint256 offsetold;
            uint256 i;
            
            // extract address implementation;
            assembly {
                implementationLogic:= mload(add(msgData,0x14))
            }
            
            msgDataPure = new bytes(msgData.length-20);
            uint256 max = msgData.length + 31;
            offsetold=20+32;        
            offsetnew=32;
            // extract keccak256 of methods's hash
            assembly { mstore(add(msgDataPure, offsetnew), mload(add(msgData, offsetold))) }
            
            // extract left data
            for (i=52+32; i<=max; i+=32) {
                offsetnew = i-20;
                offsetold = i;
                assembly { mstore(add(msgDataPure, offsetnew), mload(add(msgData, offsetold))) }
            }
            
            // finally make call
            (bool success, bytes memory data) = address(implementationLogic).delegatecall(msgDataPure);
            assembly {
                switch success
                    // delegatecall returns 0 on error.
                    case 0 { revert(add(data, 32), returndatasize()) }
                    default { return(add(data, 32), returndatasize()) }
            }
            
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../lib/StringsW0x.sol";
//import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
// import "../interfaces/ICostManager.sol";
// import "../interfaces/IFactory.sol";
import "releasemanager/contracts/CostManagerHelperERC2771Support.sol";

import "../interfaces/ISafeHook.sol";
import "../interfaces/ICommunity.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";


/**
* @dev
* Storage for any separated parts of NFT: NFTState, NFTView, etc. For all parts storage must be the same. 
* So need to extend by common contrtacts  like Ownable, Reentrancy, ERC721.
* that's why we have to leave stubs. we will implement only in certain contracts. 
* for example "name()", "symbol()" in NFTView.sol and "transfer()", "transferFrom()"  in NFTState.sol
*
* Another way are to decompose Ownable, Reentrancy, ERC721 to single flat contract and implement interface methods only for NFTMain.sol
* Or make like this 
* NFTStorage->NFTBase->NFTStubs->NFTMain, 
* NFTStorage->NFTBase->NFTState
* NFTStorage->NFTBase->NFTView
* 
* Here:
* NFTStorage - only state variables
* NFTBase - common thing that used in all contracts(for state and for view) like _ownerOf(), or can manageSeries,...
* NFTStubs - implemented stubs to make NFTMain are fully ERC721, ERC165, etc
* NFTMain - contract entry point
*/
contract NFTStorage  is 
    IERC165Upgradeable, 
    IERC721MetadataUpgradeable,
    IERC721EnumerableUpgradeable, 
    ReentrancyGuardUpgradeable,
    CostManagerHelperERC2771Support
{
    
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;
    using StringsW0x for uint256;
    
    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // Contract URI
    string internal _contractURI;    
    
    // Address of factory that produced this instance
    //address public factory;
    
    // Utility token, if any, to manage during operations
    //address public costManager;

    //address public trustedForwarder;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) internal _ownedTokens;

    // Array with all token ids, used for enumeration
    uint256[] internal _allTokens;
    
    mapping(uint64 => EnumerableSetUpgradeable.AddressSet) internal hooks;    // series ID => hooks' addresses

    // Constants for shifts
    uint8 internal constant SERIES_SHIFT_BITS = 192; // 256 - 64
    uint8 internal constant OPERATION_SHIFT_BITS = 240;  // 256 - 16
    
    // Constants representing operations
    uint8 internal constant OPERATION_INITIALIZE = 0x0;
    uint8 internal constant OPERATION_SETMETADATA = 0x1;
    uint8 internal constant OPERATION_SETSERIESINFO = 0x2;
    uint8 internal constant OPERATION_SETOWNERCOMMISSION = 0x3;
    uint8 internal constant OPERATION_SETCOMMISSION = 0x4;
    uint8 internal constant OPERATION_REMOVECOMMISSION = 0x5;
    uint8 internal constant OPERATION_LISTFORSALE = 0x6;
    uint8 internal constant OPERATION_REMOVEFROMSALE = 0x7;
    uint8 internal constant OPERATION_MINTANDDISTRIBUTE = 0x8;
    uint8 internal constant OPERATION_BURN = 0x9;
    uint8 internal constant OPERATION_BUY = 0xA;
    uint8 internal constant OPERATION_TRANSFER = 0xB;

    address internal constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint256 internal constant FRACTION = 100000;
    uint192 internal constant MAX_TOKEN_INDEX = type(uint192).max;
    
    string public baseURI;
    string public suffix;
    
//    mapping (uint256 => SaleInfoToken) public salesInfoToken;  // tokenId => SaleInfoToken

    struct FreezeInfo {
        bool exists;
        string baseURI;
        string suffix;
    }

    struct TokenInfo {
        SaleInfoToken salesInfoToken;
        FreezeInfo freezeInfo;
        uint256 hooksCountByToken; // hooks count
        uint256 allTokensIndex; // position in the allTokens array
        uint256 ownedTokensIndex; // index of the owner tokens list
        address owner; //owner address
        address tokenApproval; // approved address
    }

    struct TokenData {
        TokenInfo tokenInfo;
        SeriesInfo seriesInfo;
    }

    struct SeriesWhitelists {
        CommunitySettings transfer;
        CommunitySettings buy;
    }

    mapping (uint256 => TokenInfo) internal tokensInfo;  // tokenId => tokensInfo
    
    mapping (uint64 => SeriesInfo) public seriesInfo;  // seriesId => SeriesInfo

    mapping (uint64 => uint192) public seriesTokenIndex;  // seriesId => tokenIndex

    CommissionInfo public commissionInfo; // Global commission data 

    mapping(uint64 => uint256) public mintedCountBySeries;
    mapping(uint64 => uint256) internal mintedCountBySetSeriesInfo;

    mapping(uint64 => SeriesWhitelists) internal seriesWhitelists;
    
    // vars from ownable.sol
    address private _owner;

    struct SaleInfoToken { 
        SaleInfo saleInfo;
        uint256 ownerCommissionValue;
        uint256 authorCommissionValue;
    }
    struct SaleInfo { 
        uint64 onSaleUntil; 
        address currency;
        uint256 price;
        uint256 autoincrement;
    }

    struct SeriesInfo { 
        address payable author;
        uint32 limit;
        SaleInfo saleInfo;
        CommissionData commission;
        string baseURI;
        string suffix;
    }
    
    struct CommissionInfo {
        uint64 maxValue;
        uint64 minValue;
        CommissionData ownerCommission;
    }

    struct CommissionData {
        uint64 value;
        address recipient;
    }

    struct CommunitySettings {
        address community;
        string role;
    }

    event SeriesPutOnSale(
        uint64 indexed seriesId, 
        uint256 price, 
        uint256 autoincrement, 
        address currency, 
        uint64 onSaleUntil
    );

    event SeriesRemovedFromSale(
        uint64 indexed seriesId
    );

    event TokenRemovedFromSale(
        uint256 indexed tokenId,
        address account
    );

    event TokenPutOnSale(
        uint256 indexed tokenId, 
        address indexed seller, 
        uint256 price, 
        address currency, 
        uint64 onSaleUntil
    );
    
    event TokenBought(
        uint256 indexed tokenId, 
        address indexed seller, 
        address indexed buyer, 
        address currency, 
        uint256 price
    );

    event NewHook(
        uint64 seriesId, 
        address contractAddress
    );

    // event from ownable.sol
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    //stubs

    function approve(address/* to*/, uint256/* tokenId*/) public virtual override {revert("stub");}
    function getApproved(uint256/* tokenId*/) public view virtual override returns (address) {revert("stub");}
    function setApprovalForAll(address/* operator*/, bool/* approved*/) public virtual override {revert("stub");}
    function isApprovedForAll(address /*owner*/, address /*operator*/) public view virtual override returns (bool) {revert("stub");}
    function transferFrom(address /*from*/,address /*to*/,uint256 /*tokenId*/) public virtual override {revert("stub");}
    function safeTransferFrom(address /*from*/,address /*to*/,uint256 /*tokenId*/) public virtual override {revert("stub");}
    function safeTransferFrom(address /*from*/,address /*to*/,uint256 /*tokenId*/,bytes memory/* _data*/) public virtual override {revert("stub");}
    function safeTransfer(address /*to*/,uint256 /*tokenId*/) public virtual {revert("stub");}
    function balanceOf(address /*owner*/) public view virtual override returns (uint256) {revert("stub");}
    function ownerOf(uint256 /*tokenId*/) public view virtual override returns (address) {revert("stub");}
    function name() public view virtual override returns (string memory) {revert("stub");}
    function symbol() public view virtual override returns (string memory) {revert("stub");}
    function tokenURI(uint256 /*tokenId*/) public view virtual override returns (string memory) {revert("stub");}
    function tokenOfOwnerByIndex(address /*owner*/, uint256 /*index*/) public view virtual override returns (uint256) {revert("stub");}
    function totalSupply() public view virtual override returns (uint256) {revert("stub");}
    function tokenByIndex(uint256 /*index*/) public view virtual override returns (uint256) {revert("stub");}

    // Base
    function _getApproved(uint256 tokenId) internal view virtual returns (address) {
        require(_ownerOf(tokenId) != address(0), "ERC721: approved query for nonexistent token");
        return tokensInfo[tokenId].tokenApproval;
    }
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        address owner_ = __ownerOf(tokenId);
        require(owner_ != address(0), "ERC721: owner query for nonexistent token");
        return owner_;
    }
    function __ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return tokensInfo[tokenId].owner;
    }
    function _isApprovedForAll(address owner_, address operator) internal view virtual returns (bool) {
        return _operatorApprovals[owner_][operator];
    }
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokensInfo[tokenId].owner != address(0)
            && tokensInfo[tokenId].owner != DEAD_ADDRESS;
    }

    function _baseURIAndSuffix(
        uint256 tokenId
    ) 
        internal 
        view 
        returns(
            string memory baseURI_, 
            string memory suffix_
        ) 
    {
        
        if (tokensInfo[tokenId].freezeInfo.exists) {
            baseURI_ = tokensInfo[tokenId].freezeInfo.baseURI;
            suffix_ = tokensInfo[tokenId].freezeInfo.suffix;
        } else {

            uint64 seriesId = getSeriesId(tokenId);
            baseURI_ = seriesInfo[seriesId].baseURI;
            suffix_ = seriesInfo[seriesId].suffix;

            if (bytes(baseURI_).length == 0) {
                baseURI_ = baseURI;
            }
            if (bytes(suffix_).length == 0) {
                suffix_ = suffix;
            }
        }
    }
    
    function getSeriesId(
        uint256 tokenId
    )
        internal
        pure
        returns(uint64)
    {
        return uint64(tokenId >> SERIES_SHIFT_BITS);
    }

    function _getTokenSaleInfo(uint256 tokenId) 
        internal 
        view 
        returns
        (
            bool isOnSale,
            bool exists, 
            SaleInfo memory data,
            address owner_
        ) 
    {
        data = tokensInfo[tokenId].salesInfoToken.saleInfo;

        exists = _exists(tokenId);
        owner_ = tokensInfo[tokenId].owner;


        uint64 seriesId = getSeriesId(tokenId);
        if (owner_ != address(0)) { 
            if (data.onSaleUntil > block.timestamp) {
                isOnSale = true;
                
            } 
        } else {   
            
            SeriesInfo memory seriesData = seriesInfo[seriesId];
            if (seriesData.saleInfo.onSaleUntil > block.timestamp) {
                isOnSale = true;
                data = seriesData.saleInfo;
                owner_ = seriesData.author;

            }
        }   

        if (exists == false) {
            //using autoincrement for primarysale only
            data.price = data.price + mintedCountBySetSeriesInfo[seriesId] * data.autoincrement;
        }
    }

    // find token for primarySale
    function _getTokenSaleInfoAuto(
        uint64 seriesId
    ) 
        internal 
        returns
        (
            bool isOnSale,
            bool exists, 
            SaleInfo memory data,
            address owner_,
            uint256 tokenId
        ) 
    {
        SeriesInfo memory seriesData;
        for(uint192 i = seriesTokenIndex[seriesId]; i <= MAX_TOKEN_INDEX; i++) {
            tokenId = (uint256(seriesId) << SERIES_SHIFT_BITS) + i;

            data = tokensInfo[tokenId].salesInfoToken.saleInfo;
            exists = _exists(tokenId);
            owner_ = tokensInfo[tokenId].owner;

            if (owner_ == address(0)) { 
                seriesData = seriesInfo[seriesId];
                if (seriesData.saleInfo.onSaleUntil > block.timestamp) {
                    isOnSale = true;
                    data = seriesData.saleInfo;
                    owner_ = seriesData.author;
                    
                    if (exists == false) {
                        //using autoincrement for primarysale only
                        data.price = data.price + mintedCountBySetSeriesInfo[seriesId] * data.autoincrement;
                    }
                    
                    // save last index
                    seriesTokenIndex[seriesId] = i;
                    break;
                }
            } // else token belong to some1
        }

    }

    function _balanceOf(
        address owner_
    ) 
        internal 
        view 
        virtual 
        returns (uint256) 
    {
        require(owner_ != address(0), "ERC721: balance query for the zero address");
        return _balances[owner_];
    }

    ///////
    // // functions from context
    // function _msgSender() internal view virtual returns (address) {
    //     return msg.sender;
    // }

    // function _msgData() internal view virtual returns (bytes calldata) {
    //     return msg.data;
    // }
    function setTrustedForwarder(address forwarder) public virtual override {
        //just stub but must override
    }
    
    ///////
    // functions from ownable
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function requireOnlyOwner() internal view {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual {
        requireOnlyOwner();
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual {
        requireOnlyOwner();
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    ///////
    // ERC165 support interface
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
pragma abicoder v2;

import "./NFTStorage.sol";

//import "hardhat/console.sol";

contract NFTState is NFTStorage {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;
    using StringsW0x for uint256;
    

    function initialize(
        string memory name_, 
        string memory symbol_, 
        string memory contractURI_, 
        string memory baseURI_, 
        string memory suffixURI_, 
        address costManager_,
        address producedBy_
    ) 
        public 
        //override
        onlyInitializing
    {

        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721_init(name_, symbol_, costManager_, producedBy_);
        _contractURI = contractURI_;
        baseURI = baseURI_;
        suffix = suffixURI_;
 
    }
    

    /********************************************************************
    ****** external section *********************************************
    *********************************************************************/
    
    /**
    * @dev sets the default baseURI for the whole contract
    * @param baseURI_ the prefix to prepend to URIs
    */
    function setBaseURI(
        string calldata baseURI_
    ) 
        external
    {
        requireOnlyOwner();
        baseURI = baseURI_;
        _accountForOperation(
            OPERATION_SETMETADATA << OPERATION_SHIFT_BITS,
            0x100,
            0
        );
    }
    
    /**
    * @dev sets the default URI suffix for the whole contract
    * @param suffix_ the suffix to append to URIs
    */
    function setSuffix(
        string calldata suffix_
    ) 
        external
    {
        requireOnlyOwner();
        suffix = suffix_;
        _accountForOperation(
            OPERATION_SETMETADATA << OPERATION_SHIFT_BITS,
            0x010,
            0
        );
    }

    /**
    * @dev sets contract URI. 
    * @param newContractURI new contract URI
    */
    function setContractURI(string memory newContractURI) external {
        requireOnlyOwner();
        _contractURI = newContractURI;
        _accountForOperation(
            OPERATION_SETMETADATA << OPERATION_SHIFT_BITS,
            0x001,
            0
        );
    }

    /**
    * @dev sets information for series with 'seriesId'. 
    * @param seriesId series ID
    * @param info new info to set
    */
    function setSeriesInfo(
        uint64 seriesId, 
        SeriesInfo memory info 
    ) 
        external
    {
        CommunitySettings memory emptySettings = CommunitySettings(address(0), "");
        _setSeriesInfo(seriesId, info, emptySettings, emptySettings);
    }

    /**
    * @dev sets information for series with 'seriesId'. 
    * @param seriesId series ID
    * @param info new info to set
    */
    function setSeriesInfo(
        uint64 seriesId, 
        SeriesInfo memory info,
        CommunitySettings memory transferWhitelistSettings,
        CommunitySettings memory buyWhitelistSettings
    ) 
        external
    {
        _setSeriesInfo(seriesId, info, transferWhitelistSettings, buyWhitelistSettings);
    }

    /**
    * @dev sets information for series with 'seriesId'. 
    * @param seriesId series ID
    * @param info new info to set
    */
    function _setSeriesInfo(
        uint64 seriesId, 
        SeriesInfo memory info,
        CommunitySettings memory transferWhitelistSettings,
        CommunitySettings memory buyWhitelistSettings
    ) 
        internal
    {
        _requireCanManageSeries(seriesId);
        if (info.saleInfo.onSaleUntil > seriesInfo[seriesId].saleInfo.onSaleUntil && 
            info.saleInfo.onSaleUntil > block.timestamp
        ) {
            emit SeriesPutOnSale(
                seriesId, 
                info.saleInfo.price,
                info.saleInfo.autoincrement, 
                info.saleInfo.currency, 
                info.saleInfo.onSaleUntil
            );
        } else if (info.saleInfo.onSaleUntil <= block.timestamp ) {
            emit SeriesRemovedFromSale(seriesId);
        }
        
        seriesInfo[seriesId] = info;
        mintedCountBySetSeriesInfo[seriesId] = 0;

        seriesWhitelists[seriesId].transfer = transferWhitelistSettings;
        seriesWhitelists[seriesId].buy = buyWhitelistSettings;

        _accountForOperation(
            (OPERATION_SETSERIESINFO << OPERATION_SHIFT_BITS) | seriesId,
            uint256(uint160(info.saleInfo.currency)),
            info.saleInfo.price
        );
        
    }

    /**
    * set commission paid to contract owner
    * @param commission new commission info
    */
    function setOwnerCommission(
        CommissionInfo memory commission
    ) 
        external 
    {   
        requireOnlyOwner();
        commissionInfo = commission;

        _accountForOperation(
            OPERATION_SETOWNERCOMMISSION << OPERATION_SHIFT_BITS,
            uint256(uint160(commission.ownerCommission.recipient)),
            commission.ownerCommission.value
        );

    }

    /**
    * set commission for series
    * @param commissionData new commission data
    */
    function setCommission(
        uint64 seriesId, 
        CommissionData memory commissionData
    ) 
        external 
    {
        _requireCanManageSeries(seriesId);
        require(
            (
                commissionData.value <= commissionInfo.maxValue &&
                commissionData.value >= commissionInfo.minValue &&
                commissionData.value + commissionInfo.ownerCommission.value < FRACTION
            ),
            "COMMISSION_INVALID"
        );
        require(commissionData.recipient != address(0), "RECIPIENT_INVALID");
        seriesInfo[seriesId].commission = commissionData;
        
        _accountForOperation(
            (OPERATION_SETCOMMISSION << OPERATION_SHIFT_BITS) | seriesId,
            commissionData.value,
            uint256(uint160(commissionData.recipient))
        );
        
    }

    /**
    * clear commission for series
    * @param seriesId seriesId
    */
    function removeCommission(
        uint64 seriesId
    ) 
        external 
    {
        _requireCanManageSeries(seriesId);
        delete seriesInfo[seriesId].commission;
        
        _accountForOperation(
            (OPERATION_REMOVECOMMISSION << OPERATION_SHIFT_BITS) | seriesId,
            0,
            0
        );
        
    }

    /**
    * @dev lists on sale NFT with defined token ID with specified terms of sale
    * @param tokenId token ID
    * @param price price for sale 
    * @param currency currency of sale 
    * @param duration duration of sale 
    */
    function listForSale(
        uint256 tokenId,
        uint256 price,
        address currency,
        uint64 duration
    )
        external 
    {
        (bool success, /*bool isExists*/, /*SaleInfo memory data*/, /*address owner*/) = _getTokenSaleInfo(tokenId);
        
        _requireCanManageToken(tokenId);
        require(!success, "already on sale");
        require(duration > 0, "invalid duration");

        uint64 seriesId = getSeriesId(tokenId);
        SaleInfo memory newSaleInfo = SaleInfo({
            onSaleUntil: uint64(block.timestamp) + duration,
            currency: currency,
            price: price,
            autoincrement:0
        });
        SaleInfoToken memory saleInfoToken = SaleInfoToken({
            saleInfo: newSaleInfo,
            ownerCommissionValue: commissionInfo.ownerCommission.value,
            authorCommissionValue: seriesInfo[seriesId].commission.value
        });
        _setSaleInfo(tokenId, saleInfoToken);

        emit TokenPutOnSale(
            tokenId, 
            _msgSender(), 
            newSaleInfo.price, 
            newSaleInfo.currency, 
            newSaleInfo.onSaleUntil
        );
        
        _accountForOperation(
            (OPERATION_LISTFORSALE << OPERATION_SHIFT_BITS) | seriesId,
            uint256(uint160(currency)),
            price
        );
    }
    
    /**
    * @dev removes from sale NFT with defined token ID
    * @param tokenId token ID
    */
    function removeFromSale(
        uint256 tokenId
    )
        external 
    {
        (bool success, /*bool isExists*/, SaleInfo memory data, /*address owner*/) = _getTokenSaleInfo(tokenId);
        require(success, "token not on sale");
        _requireCanManageToken(tokenId);
        clearOnSaleUntil(tokenId);

        emit TokenRemovedFromSale(tokenId, _msgSender());
        
        uint64 seriesId = getSeriesId(tokenId);
        _accountForOperation(
            (OPERATION_REMOVEFROMSALE << OPERATION_SHIFT_BITS) | seriesId,
            uint256(uint160(data.currency)),
            data.price
        );
    }

    /**
    * @dev mints and distributes NFTs with specified IDs
    * to specified addresses
    * @param tokenIds list of NFT IDs t obe minted
    * @param addresses list of receiver addresses
    */
    function mintAndDistribute(
        uint256[] memory tokenIds, 
        address[] memory addresses
    )
        external 
    {
        uint256 len = addresses.length;
        require(tokenIds.length == len, "lengths should be the same");

        for(uint256 i = 0; i < len; i++) {
            _requireCanManageSeries(getSeriesId(tokenIds[i]));
            _mint(addresses[i], tokenIds[i]);
        }
        
        _accountForOperation(
            OPERATION_MINTANDDISTRIBUTE << OPERATION_SHIFT_BITS,
            len,
            0
        );
    }

    /**
    * @dev mints and distributes `amount` NFTs by `seriesId` to `account`
    * @param seriesId seriesId
    * @param account receiver addresses
    * @param amount amount of tokens
    * @custom:calledby owner or series author
    * @custom:shortd mint and distribute new tokens
    */
    function mintAndDistributeAuto(
        uint64 seriesId, 
        address account,
        uint256 amount
    )
        external
    {
        _requireCanManageSeries(seriesId);

        uint256 tokenId;
        uint256 tokenIndex = (uint256(seriesId) << SERIES_SHIFT_BITS);
        uint192 j;

        for(uint256 i = 0; i < amount; i++) {
            for(j = seriesTokenIndex[seriesId]; j < MAX_TOKEN_INDEX; j++) {
                tokenId = tokenIndex + j;

                if (tokensInfo[tokenId].owner == address(0)) { 
                    // save last index
                    seriesTokenIndex[seriesId] = j;

                    break;
                }
                
            }
            // unreachable but must be
            if (j == MAX_TOKEN_INDEX) { revert("series max token limit exceeded");}
            _mint(account, tokenId);
        }

        _accountForOperation(
            OPERATION_MINTANDDISTRIBUTE << OPERATION_SHIFT_BITS,
            amount,
            0
        );
        
        
    }
   
    /********************************************************************
    ****** public section ***********************************************
    *********************************************************************/
    function buy(
        uint256[] memory tokenIds,
        address currency,
        uint256 totalPrice,
        bool safe,
        uint256 hookCount,
        address buyFor
    ) 
        public 
        virtual
        payable 
        //nonReentrant 
    {
        require(tokenIds.length > 0, "invalid tokenIds");
        uint64 seriesId = getSeriesId(tokenIds[0]);

        validateBuyer(seriesId);
        validateHookCount(seriesId, hookCount);
        
        uint256 left = totalPrice;

        for(uint256 i = 0; i < tokenIds.length; i ++) {
            (bool success, bool exists, SaleInfo memory data, address beneficiary) = _getTokenSaleInfo(tokenIds[i]);

            //require(currency == data.currency, "wrong currency for sale");
            require(left >= data.price, "insufficient amount sent");
            left -= data.price;

            _commissions_payment(
                tokenIds[i], 
                currency, 
                (currency == address(0) ? true : false), 
                data.price, 
                success, 
                data, 
                beneficiary
            );

            _buy(tokenIds[i], exists, data, beneficiary, buyFor, safe);
            
            
            _accountForOperation(
                (OPERATION_BUY << OPERATION_SHIFT_BITS) | seriesId, 
                0,
                data.price
            );
        }

    }

    /**
    * @dev buys NFT for native coin with undefined id. 
    * Id will be generate as usually by auto inrement but belong to seriesId
    * and transfer token if it is on sale
    * @param seriesId series ID whene we can find free token to buy
    * @param price amount of specified native coin to pay
    * @param safe use safeMint and safeTransfer or not, 
    * @param hookCount number of hooks 
    */
    function buyAuto(
        uint64 seriesId, 
        uint256 price, 
        bool safe, 
        uint256 hookCount
    ) 
        public 
        payable 
        //nonReentrant 
    {

        _buyAuto(seriesId, address(0), price, safe, hookCount, _msgSender());
    }
    /**
    * @dev buys NFT for native coin with undefined id. 
    * Id will be generate as usually by auto inrement but belong to seriesId
    * and transfer token if it is on sale
    * @param seriesId series ID whene we can find free token to buy
    * @param price amount of specified native coin to pay
    * @param safe use safeMint and safeTransfer or not, 
    * @param hookCount number of hooks 
    * @param buyFor address of new nft owner
    */
    function buyAuto(
        uint64 seriesId, 
        uint256 price, 
        bool safe, 
        uint256 hookCount,
        address buyFor
    ) 
        public 
        payable 
        //nonReentrant 
    {

        _buyAuto(seriesId, address(0), price, safe, hookCount, buyFor);
    }

    function _buyAuto(
        uint64 seriesId, 
        address currency, 
        uint256 price, 
        bool safe, 
        uint256 hookCount,
        address buyFor
    ) 
        internal
    {
        
        validateBuyer(seriesId);
        validateHookCount(seriesId, hookCount);

        (bool success, bool exists, SaleInfo memory data, address beneficiary, uint256 tokenId) = _getTokenSaleInfoAuto(seriesId);

        _commissions_payment(tokenId, currency, (currency == address(0) ? true : false), price, success, data, beneficiary);
        
        _buy(tokenId, exists, data, beneficiary, buyFor, safe);
        
        
        _accountForOperation(
            (OPERATION_BUY << OPERATION_SHIFT_BITS) | seriesId, 
            0,
            price
        );

    }
    
    /**
    * @dev buys NFT for native coin with undefined id. 
    * Id will be generate as usually by auto inrement but belong to seriesId
    * and transfer token if it is on sale
    * @param seriesId series ID whene we can find free token to buy
    * @param currency address of token to pay with
    * @param price amount of specified token to pay
    * @param safe use safeMint and safeTransfer or not
    * @param hookCount number of hooks 
    */
    function buyAuto(
        uint64 seriesId, 
        address currency, 
        uint256 price, 
        bool safe, 
        uint256 hookCount
    ) 
        public 
        //nonReentrant 
    {

        _buyAuto(seriesId, currency, price, safe, hookCount, _msgSender());
    }

    /**
    * @dev buys NFT for native coin with undefined id. 
    * Id will be generate as usually by auto inrement but belong to seriesId
    * and transfer token if it is on sale
    * @param seriesId series ID whene we can find free token to buy
    * @param currency address of token to pay with
    * @param price amount of specified token to pay
    * @param safe use safeMint and safeTransfer or not
    * @param hookCount number of hooks 
    * @param buyFor address of new nft owner
    */
    function buyAuto(
        uint64 seriesId, 
        address currency, 
        uint256 price, 
        bool safe, 
        uint256 hookCount,
        address buyFor
    ) 
        public 
        //nonReentrant 
    {
        _buyAuto(seriesId, currency, price, safe, hookCount, buyFor);
    }


    /** 
    * @dev sets name and symbol for contract
    * @param newName new name 
    * @param newSymbol new symbol 
    */
    function setNameAndSymbol(
        string memory newName, 
        string memory newSymbol
    ) 
        public 
    {
        requireOnlyOwner();
        _setNameAndSymbol(newName, newSymbol);
    }
    
  
    

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = _ownerOf(tokenId);

        require(to != owner, "ERC721: approval to current owner");
        address ms = _msgSender();
        require(
            ms == owner || _isApprovedForAll(owner, ms),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        _requireCanManageToken(tokenId);

        _transfer(from, to, tokenId);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _requireCanManageToken(tokenId);
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Transfers `tokenId` token from sender to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by sender.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address to,
        uint256 tokenId
    ) public virtual {
        _requireCanManageToken(tokenId);
        _transfer(_msgSender(), to, tokenId);
    }

    /**
     * @dev Safely transfers `tokenId` token from sender to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by sender.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransfer(
        address to,
        uint256 tokenId
    ) public virtual override {
        _requireCanManageToken(tokenId);
        _safeTransfer(_msgSender(), to, tokenId, "");
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        _requireCanManageToken(tokenId);
        _burn(tokenId);
        
        _accountForOperation(
            OPERATION_BURN << OPERATION_SHIFT_BITS,
            tokenId,
            0
        );
    }

    
   /**
    * @dev the owner should be absolutely sure they trust the trustedForwarder
    * @param trustedForwarder_ must be a smart contract that was audited
    */
    function setTrustedForwarder(
        address trustedForwarder_
    )
        public 
        override
    {
        requireOnlyOwner();
        _setTrustedForwarder(trustedForwarder_);
    }

    /**
    * @dev link safeHook contract to certain series
    * @param seriesId series ID
    * @param contractAddress address of SafeHook contract
    */
    function pushTokenTransferHook(
        uint64 seriesId, 
        address contractAddress
    )
        public 
    {
        requireOnlyOwner();
        try ISafeHook(contractAddress).supportsInterface(type(ISafeHook).interfaceId) returns (bool success) {
            if (success) {
                hooks[seriesId].add(contractAddress);
            } else {
                revert("wrong interface");
            }
        } catch {
            revert("wrong interface");
        }

        emit NewHook(seriesId, contractAddress);

    }

    function freeze(
        uint256 tokenId
    ) 
        public 
    {
        string memory baseURI;
        string memory suffix;
        (baseURI, suffix) = _baseURIAndSuffix(tokenId);
        _freeze(tokenId, baseURI, suffix);
    }

    function freeze(
        uint256 tokenId, 
        string memory baseURI, 
        string memory suffix
    ) 
        public 
    {
        _freeze(tokenId, baseURI, suffix);
    }

    
    function unfreeze(
        uint256 tokenId
    ) 
        public 
    {
        tokensInfo[tokenId].freezeInfo.exists = false;
    }
    

    /********************************************************************
    ****** internal section *********************************************
    *********************************************************************/

    function validateBuyer(uint64 seriesId) internal {

        if (seriesWhitelists[seriesId].buy.community != address(0)) {
            bool success = ICommunity(seriesWhitelists[seriesId].buy.community).isMemberHasRole(_msgSender(), seriesWhitelists[seriesId].buy.role);
            //require(success, "buyer not in whitelist");
            require(success, "BUYER_INVALID");
        }
    }

    function _freeze(uint256 tokenId, string memory baseURI_, string memory suffix_) internal 
    {
        require(_ownerOf(tokenId) == _msgSender(), "token isn't owned by sender");
        tokensInfo[tokenId].freezeInfo.exists = true;
        tokensInfo[tokenId].freezeInfo.baseURI = baseURI_;
        tokensInfo[tokenId].freezeInfo.suffix = suffix_;
        
    }
   
    function _transferOwnership(
        address newOwner
    ) 
        internal 
        virtual 
        override
    {
        super._transferOwnership(newOwner);
        _setTrustedForwarder(address(0));
    }

    function _buy(
        uint256 tokenId, 
        bool exists, 
        SaleInfo memory data, 
        address owner, 
        address recipient, 
        bool safe
    ) 
        internal 
        virtual 
    {
        _storeHookCount(tokenId);

        if (exists) {
            if (safe) {
                _safeTransfer(owner, recipient, tokenId, new bytes(0));
            } else {
                _transfer(owner, recipient, tokenId);
            }
            emit TokenBought(
                tokenId, 
                owner, 
                recipient, 
                data.currency, 
                data.price
            );
        } else {

            if (safe) {
                _safeMint(recipient, tokenId);
            } else {
                _mint(recipient, tokenId);
            }
            emit Transfer(owner, recipient, tokenId);
            emit TokenBought(
                tokenId, 
                owner, 
                recipient, 
                data.currency, 
                data.price
            );
        }
         
    }

    
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(
        string memory name_, 
        string memory symbol_, 
        address costManager_, 
        address producedBy_
    ) 
        internal 
        onlyInitializing
    {
        
        _setNameAndSymbol(name_, symbol_);
        
        __CostManagerHelper_init(_msgSender());
        _setCostManager(costManager_);

        _accountForOperation(
            OPERATION_INITIALIZE << OPERATION_SHIFT_BITS,
            uint256(uint160(producedBy_)),
            0
        );
    }
    
    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "recipient must implement ERC721Receiver interface");
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event. if flag `skipEvent` is false
     */
    function _mint(
        address to, 
        uint256 tokenId
    ) 
        internal 
        virtual 
    {
        _storeHookCount(tokenId);

        require(to != address(0), "can't mint to the zero address");
        require(tokensInfo[tokenId].owner == address(0), "token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        tokensInfo[tokenId].owner = to;

        uint64 seriesId = getSeriesId(tokenId);
        mintedCountBySeries[seriesId] += 1;
        mintedCountBySetSeriesInfo[seriesId] += 1;

        if (seriesInfo[seriesId].limit != 0) {
            require(
                mintedCountBySeries[seriesId] <= seriesInfo[seriesId].limit, 
                "series token limit exceeded"
            );
        }
        

        emit Transfer(address(0), to, tokenId);
        
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
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        
        _balances[DEAD_ADDRESS] += 1;
        tokensInfo[tokenId].owner = DEAD_ADDRESS;
        clearOnSaleUntil(tokenId);
        emit Transfer(owner, DEAD_ADDRESS, tokenId);

    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {

        require(_ownerOf(tokenId) == from, "token isn't owned by from address");
        require(to != address(0), "can't transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        tokensInfo[tokenId].owner = to;

        clearOnSaleUntil(tokenId);

        emit Transfer(from, to, tokenId);
        
        _accountForOperation(
            (OPERATION_TRANSFER << OPERATION_SHIFT_BITS) | getSeriesId(tokenId),
            uint256(uint160(from)),
            uint256(uint160(to))
        );
        
    }
    
    /**
    * @dev sets sale info for the NFT with 'tokenId'
    * @param tokenId token ID
    * @param info information about sale 
    */
    function _setSaleInfo(
        uint256 tokenId, 
        SaleInfoToken memory info 
    ) 
        internal 
    {
        //salesInfoToken[tokenId] = info;
        tokensInfo[tokenId].salesInfoToken = info;
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        tokensInfo[tokenId].tokenApproval = to;
        emit Approval(_ownerOf(tokenId), to, tokenId);
    }
    
    /** 
    * @dev sets name and symbol for contract
    * @param newName new name 
    * @param newSymbol new symbol 
    */
    function _setNameAndSymbol(
        string memory newName, 
        string memory newSymbol
    ) 
        internal 
    {
        _name = newName;
        _symbol = newSymbol;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {

        //safe hook
        uint64 seriesId = uint64(tokenId >> SERIES_SHIFT_BITS);
        for (uint256 i = 0; i < tokensInfo[tokenId].hooksCountByToken; i++) {
            try ISafeHook(hooks[seriesId].at(i)).executeHook(from, to, tokenId)
			returns (bool success) {
                if (!success) {
                    revert("Transfer Not Authorized");
                }
            } catch Error(string memory reason) {
                // This is executed in case revert() was called with a reason
	            revert(reason);
	        } catch {
                revert("Transfer Not Authorized");
            }
        }
        ////
        if (to != address(0) && seriesWhitelists[seriesId].transfer.community != address(0)) {
            bool success = ICommunity(seriesWhitelists[seriesId].transfer.community).isMemberHasRole(to, seriesWhitelists[seriesId].transfer.role);
            //require(success, "recipient not in whitelist");
            require(success, "RECIPIENT_INVALID");
            
        }
    ////

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }

        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }

    }

    function clearOnSaleUntil(uint256 tokenId) internal {
        if (tokensInfo[tokenId].salesInfoToken.saleInfo.onSaleUntil > 0 ) tokensInfo[tokenId].salesInfoToken.saleInfo.onSaleUntil = 0;
    }

    function _requireCanManageSeries(uint64 seriesId) internal view virtual {
        require(_canManageSeries(seriesId), "you can't manage this series");
    }
             
    function _requireCanManageToken(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "token doesn't exist");
        require(_canManageToken(tokenId), "you can't manage this token");
    }

    function _canManageToken(uint256 tokenId) internal view returns (bool) {
        return __ownerOf(tokenId) == _msgSender()
            || _getApproved(tokenId) == _msgSender()
            || _isApprovedForAll(__ownerOf(tokenId), _msgSender());
    }

    function _canManageSeries(uint64 seriesId) internal view returns(bool) {
        return owner() == _msgSender() || seriesInfo[seriesId].author == _msgSender();
    }
    
    /**
    * @dev returns count of hooks for series with `seriesId`
    * @param seriesId series ID
    */
    function hooksCount(
        uint64 seriesId
    ) 
        internal 
        view 
        returns(uint256) 
    {
        return hooks[seriesId].length();
    }

    /**
    * @dev validates hook count
    * @param seriesId series ID
    * @param hookCount hook count
    */
    function validateHookCount(
        uint64 seriesId,
        uint256 hookCount
    ) 
        internal 
        view 
    {
        require(hookCount == hooksCount(seriesId), "wrong hookCount");
    }

    /** 
    * @dev used to storage hooksCountByToken at this moment
    */
    function _storeHookCount(
        uint256 tokenId
    )
        internal
    {
        tokensInfo[tokenId].hooksCountByToken = hooks[uint64(tokenId >> SERIES_SHIFT_BITS)].length();
    }

    /**
    * payment while buying. combined version for payable and for tokens
    */
    function _commissions_payment(
        uint256 tokenId,
        address currency,
        bool isPayable,
        uint256 price, 
        bool success,
        SaleInfo memory data, 
        address beneficiary
    )
        internal
    {
        require(success, "token is not on sale");

        require(
            (isPayable && address(0) == data.currency) ||
            (!isPayable && currency == data.currency),
            "wrong currency for sale"
        );

        uint256 amount = (isPayable ? msg.value : IERC20Upgradeable(data.currency).allowance(_msgSender(), address(this)));
        require(amount >= data.price && price >= data.price, "insufficient amount sent");

        uint256 left = data.price;
        (address[2] memory addresses, uint256[2] memory values, uint256 length) = calculateCommission(tokenId, data.price);

        // commissions payment
        bool transferSuccess;
        for(uint256 i = 0; i < length; i++) {
            if (isPayable) {
                (transferSuccess, ) = addresses[i].call{gas: 3000, value: values[i]}(new bytes(0));
                require(transferSuccess, "TRANSFER_COMMISSION_FAILED");
            } else {
                IERC20Upgradeable(data.currency).transferFrom(_msgSender(), addresses[i], values[i]);
            }
            left -= values[i];
        }

        // payment to beneficiary and refund
        if (isPayable) {
            (transferSuccess, ) = beneficiary.call{gas: 3000, value: left}(new bytes(0));
            require(transferSuccess, "TRANSFER_TO_OWNER_FAILED");

            // try to refund
            if (amount > data.price) {
                // todo 0: if  EIP-2771 using. to whom refund will be send? msg.sender or trusted forwarder
                (transferSuccess, ) = msg.sender.call{gas: 3000, value: (amount - data.price)}(new bytes(0));
                require(transferSuccess, "REFUND_FAILED");
            }

        } else {
            IERC20Upgradeable(data.currency).transferFrom(_msgSender(), beneficiary, left);
        }

    }

    /**
    * @dev calculate commission for `tokenId`
    *  if param exists equal true, then token doesn't exists yet. 
    *  otherwise we should use snapshot parameters: ownerCommission/authorCommission, that hold during listForSale.
    *  used to prevent increasing commissions
    * @param tokenId token ID to calculate commission
    * @param price amount of specified token to pay 
    */
    function calculateCommission(
        uint256 tokenId,
        uint256 price
    ) 
        internal 
        view 
        returns(
            address[2] memory addresses, 
            uint256[2] memory values,
            uint256 length
        ) 
    {
        uint64 seriesId = getSeriesId(tokenId);
        length = 0;
        uint256 sum;
        // contract owner commission
        if (commissionInfo.ownerCommission.recipient != address(0)) {
            uint256 oc = tokensInfo[tokenId].salesInfoToken.ownerCommissionValue;
            if (commissionInfo.ownerCommission.value < oc)
                oc = commissionInfo.ownerCommission.value;
            if (oc != 0) {
                addresses[length] = commissionInfo.ownerCommission.recipient;
                sum += oc;
                values[length] = oc * price / FRACTION;
                length++;
            }
        }

        // author commission
        if (seriesInfo[seriesId].commission.recipient != address(0)) {
            uint256 ac = tokensInfo[tokenId].salesInfoToken.authorCommissionValue;
            if (seriesInfo[seriesId].commission.value < ac) 
                ac = seriesInfo[seriesId].commission.value;
            if (ac != 0) {
                addresses[length] = seriesInfo[seriesId].commission.recipient;
                sum += ac;
                values[length] = ac * price / FRACTION;
                length++;
            }
        }

        require(sum < FRACTION, "invalid commission");

    }

    /********************************************************************
    ****** private section **********************************************
    *********************************************************************/

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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }


   
    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = _balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        tokensInfo[tokenId].ownedTokensIndex = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        tokensInfo[tokenId].allTokensIndex = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _balanceOf(from) - 1;
        uint256 tokenIndex = tokensInfo[tokenId].ownedTokensIndex;

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            tokensInfo[lastTokenId].ownedTokensIndex = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        tokensInfo[tokenId].ownedTokensIndex = 0;
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = tokensInfo[tokenId].allTokensIndex;

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        tokensInfo[lastTokenId].allTokensIndex = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        tokensInfo[tokenId].allTokensIndex = 0;
        _allTokens.pop();
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
pragma abicoder v2;

import "./NFTStorage.sol";

contract NFTView is NFTStorage {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    // using AddressUpgradeable for address;
    using StringsW0x for uint256;
    
    /**
    * custom realization EIP2771 for communicate NTMain->NFTView
    * - NTMain should !obligatory! append to msg.data (msg.sender). and only for view calls (NFTView)
    * - msg.data(NFTView) shouldn't be empty and shoud exist at least 20 bytes to identify sender
    */
    // function _msgSender() internal pure override returns (address signer) {
    //     require(msg.data.length>=20, "incorrect msg.data");
    //     assembly {
    //         signer := shr(96,calldataload(sub(calldatasize(),20)))
    //     }
    // }
    //!!!!!!!!!!!!!

    /********************************************************************
    ****** external section *********************************************
    *********************************************************************/

    /**
    * @dev returns the list of all NFTs owned by 'account' with limit
    * @param account address of account
    */
    function tokensByOwner(
        address account,
        uint32 limit
    ) 
        external
        view
        returns (uint256[] memory ret)
    {
        return _tokensByOwner(account, limit);
    }

    /**
    * @dev returns the list of hooks for series with `seriesId`
    * @param seriesId series ID
    */
    function getHookList(
        uint64 seriesId
    ) 
        external 
        view 
        returns(address[] memory) 
    {
        uint256 len = hooksCount(seriesId);
        address[] memory allHooks = new address[](len);
        for (uint256 i = 0; i < hooksCount(seriesId); i++) {
            allHooks[i] = hooks[seriesId].at(i);
        }
        return allHooks;
    }

    /********************************************************************
    ****** public section *********************************************
    *********************************************************************/
    function getSeriesInfo(
        uint64 seriesId
    ) 
        public 
        view 
        returns (
            address payable author,
            uint32 limit,
            //SaleInfo saleInfo;
            uint64 onSaleUntil,
            address currency,
            uint256 price,
            ////
            //CommissionData commission;
            uint64 value,
            address recipient,
            /////
            string memory baseURI,
            string memory suffix
        ) 
    {
        author = seriesInfo[seriesId].author;
        limit = seriesInfo[seriesId].limit;
        //
        onSaleUntil = seriesInfo[seriesId].saleInfo.onSaleUntil;
        currency = seriesInfo[seriesId].saleInfo.currency;
        price = seriesInfo[seriesId].saleInfo.price;
        //
        value = seriesInfo[seriesId].commission.value;
        recipient = seriesInfo[seriesId].commission.recipient;
        //
        baseURI = seriesInfo[seriesId].baseURI;
        suffix = seriesInfo[seriesId].suffix;

    }
    /**
    * @dev tells the caller whether they can set info for a series,
    * manage amount of commissions for the series,
    * mint and distribute tokens from it, etc.
    * @param account address to check
    * @param seriesId the id of the series being asked about
    */
    function canManageSeries(address account, uint64 seriesId) public view returns (bool) {
        return _canManageSeries(account, seriesId);
    }
    /**
    * @dev tells the caller whether they can transfer an existing token,
    * list it for sale and remove it from sale.
    * Tokens can be managed by their owner
    * or approved accounts via {approve} or {setApprovalForAll}.
    * @param account address to check
    * @param tokenId the id of the tokens being asked about
    */
    function canManageToken(address account, uint256 tokenId) public view returns (bool) {
        return _canManageToken(account, tokenId);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function tokenExists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    /**
    * @dev returns contract URI. 
    */
    function contractURI() public view returns(string memory){
        return _contractURI;
    }

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < _balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override /*override(ERC165Upgradeable, IERC165Upgradeable)*/ returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC721EnumerableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        // require(owner != address(0), "ERC721: balance query for the zero address");
        // return _balances[owner];
        return _balanceOf(owner);
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = __ownerOf(tokenId);
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(
        uint256 tokenId
    ) 
        public 
        view 
        virtual 
        override
        returns (string memory) 
    {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        string memory _tokenIdHexString = tokenId.toHexString();

        string memory baseURI_;
        string memory suffix_;
        (baseURI_, suffix_) = _baseURIAndSuffix(tokenId);

        // If all are set, concatenate
        if (bytes(_tokenIdHexString).length > 0) {
            return string(abi.encodePacked(baseURI_, _tokenIdHexString, suffix_));
        }
        return "";
    }

    
    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        return _getApproved(tokenId);
    }

    
    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _isApprovedForAll(owner, operator);
    }

    /**
    * @dev returns if token is on sale or not, 
    * whether it exists or not,
    * as well as data about the sale and its owner
    * @param tokenId token ID 
    */
    function getTokenSaleInfo(uint256 tokenId) 
        public 
        view 
        returns
        (
            bool isOnSale,
            bool exists, 
            SaleInfo memory data,
            address owner
        ) 
    {
        return _getTokenSaleInfo(tokenId);
    }

    /**
    * @dev returns info for token and series that belong to
    * @param tokenId token ID 
    */
    function tokenInfo(
        uint256 tokenId
    )
        public 
        view
        returns(TokenData memory)
    {
        uint64 seriesId = getSeriesId(tokenId);
        return TokenData(tokensInfo[tokenId], seriesInfo[seriesId]);
    }

    /********************************************************************
    ****** internal section *********************************************
    *********************************************************************/

    /**
    * @param account account
    * @param limit limit
    */
    function _tokensByOwner(
        address account,
        uint32 limit
    ) 
        internal
        view
        returns (uint256[] memory array)
    {
        uint256 len = _balanceOf(account);
        if (len > 0) {
            len = (limit != 0 && limit < len) ? limit : len;
            array = new uint256[](len);
            for (uint256 i = 0; i < len; i++) {
                array[i] = _ownedTokens[account][i];
            }
        }
    }

    /**
    * @dev returns count of hooks for series with `seriesId`
    * @param seriesId series ID
    */
    function hooksCount(
        uint64 seriesId
    ) 
        internal 
        view 
        returns(uint256) 
    {
        return hooks[seriesId].length();
    }

    function _canManageSeries(address account, uint64 seriesId) internal view returns(bool) {
        return owner() == account || seriesInfo[seriesId].author == account;
    }
    
    function _canManageToken(address account, uint256 tokenId) internal view returns (bool) {
        return __ownerOf(tokenId) == account
            || _getApproved(tokenId) == account
            || _isApprovedForAll(__ownerOf(tokenId), account);
    }
   
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity 0.8.11;

/**
 * @dev String operations.
 */
library StringsW0x {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    
    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        int256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, int256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * uint256(length));
        for (int256 i = 2 * length - 1; i > -1; --i) {
            buffer[uint256(i)] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICostManager.sol";
import "./interfaces/ICostManagerFactoryHelper.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "trustedforwarder/contracts/TrustedForwarder.sol";

/**
* used for instances that have created(cloned) by factory.
*/
abstract contract CostManagerHelperERC2771Support is TrustedForwarder {
    using AddressUpgradeable for address;

    address public costManager;
    address internal factory;

    /** 
    * @dev sets the costmanager token
    * @param costManager_ new address of costmanager token, or 0
    */
    function overrideCostManager(address costManager_) external {
        // require factory owner or operator
        // otherwise needed deployer(!!not contract owner) in cases if was deployed manually
        require (
            (factory.isContract()) 
                ?
                    ICostManagerFactoryHelper(factory).canOverrideCostManager(_msgSender(), address(this))
                :
                    factory == _msgSender()
            ,
            "cannot override"
        );
        
        _setCostManager(costManager_);
    }

    function __CostManagerHelper_init(address factory_) internal onlyInitializing
    {
        factory = factory_;
    }

     /**
     * @dev Private function that tells contract to account for an operation
     * @param info uint256 The operation ID (first 8 bits). in other bits any else info
     * @param param1 uint256 Some more information, if any
     * @param param2 uint256 Some more information, if any
     */
    function _accountForOperation(uint256 info, uint256 param1, uint256 param2) internal {
        if (costManager != address(0)) {
            try ICostManager(costManager).accountForOperation(
                msg.sender, info, param1, param2
            )
            returns (uint256 /*spent*/, uint256 /*remaining*/) {
                // if error is not thrown, we are fine
            } catch Error(string memory reason) {
                // This is executed in case revert() was called with a reason
                revert(reason);
            } catch {
                revert("unknown error");
            }
        }
    }
    
    function _setCostManager(address costManager_) internal {
        costManager = costManager_;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface ISafeHook is IERC165Upgradeable {
    function executeHook(address from, address to, uint256 tokenId) external returns(bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ICommunity {
    function isMemberHasRole(address account, string memory rolename) external returns(bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface ICostManager/* is IERC165Upgradeable*/ {
    function accountForOperation(
        address sender, 
        uint256 info, 
        uint256 param1, 
        uint256 param2
    ) 
        external 
        returns(uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICostManagerFactoryHelper {
    
    function canOverrideCostManager(address account, address instance) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract TrustedForwarder is Initializable {

    address private _trustedForwarder;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __TrustedForwarder_init() internal onlyInitializing {
        _trustedForwarder = address(0);
    }


    /**
    * @dev setup trusted forwarder address
    * @param forwarder trustedforwarder's address to set
    * @custom:shortd setup trusted forwarder
    * @custom:calledby owner
    */
    function _setTrustedForwarder(
        address forwarder
    ) 
        internal 
      //  onlyOwner 
        //excludeTrustedForwarder 
    {
        //require(owner() != forwarder, "FORWARDER_CAN_NOT_BE_OWNER");
        _trustedForwarder = forwarder;
    }
    function setTrustedForwarder(address forwarder) public virtual;
    /**
    * @dev checking if forwarder is trusted
    * @param forwarder trustedforwarder's address to check
    * @custom:shortd checking if forwarder is trusted
    */
    function isTrustedForwarder(
        address forwarder
    ) 
        external
        view 
        returns(bool) 
    {
        return _isTrustedForwarder(forwarder);
    }

    /**
    * @dev implemented EIP-2771
    */
    function _msgSender(
    ) 
        internal 
        view 
        returns (address signer) 
    {
        signer = msg.sender;
        if (msg.data.length>=20 && _isTrustedForwarder(signer)) {
            assembly {
                signer := shr(96,calldataload(sub(calldatasize(),20)))
            }
        }    
    }

    // function transferOwnership(
    //     address newOwner
    // ) public 
    //     virtual 
    //     override 
    //     onlyOwner 
    // {
    //     require(msg.sender != _trustedForwarder, "DENIED_FOR_FORWARDER");
    //     if (newOwner == _trustedForwarder) {
    //         _trustedForwarder = address(0);
    //     }
    //     super.transferOwnership(newOwner);
        
    // }

    function _isTrustedForwarder(
        address forwarder
    ) 
        internal
        view 
        returns(bool) 
    {
        return forwarder == _trustedForwarder;
    }


  

}