// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IControl.sol";
import "./IVaultRewards.sol";
import "./ILazymint.sol";
import "./IVaultRent.sol";
import "../Mortgage/IMortgageControl.sol";
import "../Mortgage/IVaultLenders.sol";
import "../Mortgage/IMortgageInterest.sol";
import "../Mortgage/HelperRewardsContract.sol";
import "../Mortgage/TokenInfo.sol";

/// @title A contract that Calculate the Rewards per User
/// @author @Mike_Bello90
/// @notice You can use this contract to calculate the user rewards for Panoram Fees
contract RewardsPayer is AccessControl, HelperRewardsContract, IMortgageInterest {

    IControl private controlContract;
    IMortgageControl mortgageControl;
    TokenInfo public tokenInfo;
    /// @dev Struct para registrar y validar datos necesarios de un usuario para la entrega y calculo del Reward
    struct UserRewards {
        uint256 rewardPerBuilder;
        uint256 lastTimePayBuilder;
        uint256 lastTimeCalcBuilder;
        uint256 rewardPerBuilderNFT; // estadistica para el front
        uint256 rewardPerHolder;
        uint256 lastTimePayHolder;
        uint256 lastTimeCalcHolder;
        uint256 rewardPerHolderNFT; // estadistica para el front
    }

    struct UserRewardsRent {
        uint256 rewardPerRent;
        uint256 lastTimePayRent;
        uint256 lastTimeCalcRent;
        uint256 rewardPerRentNFT; // estadistica para el front
    }
    /// @dev salvamos la wallet del user y luego en el mapping interno salvamos la address de la collection y la estructura con sus rewards de renta por coleccion.
    mapping(address => mapping(address => UserRewardsRent))
        private collectionRewardsRentPerUser;

    // mapping to save the general user rewards for builder and Holder (contando los NFTs del user sin importar la coleccion)
    mapping(address => UserRewards) private userRewardsBH;

    constructor(address _tokenInfo, address _Mortgagecontrol,address _controlContract,address _token,
    address vaultLenders, address VaultRewardsContract, address PoolRewardsLenders) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEV_ROLE, msg.sender);
        _setupRole(DEV_ROLE, relayAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x526324c87e3e44630971fd2f6d9D69f3914e01DA);
        _setupRole(DEV_ROLE, 0x526324c87e3e44630971fd2f6d9D69f3914e01DA);
        mortgageControl = IMortgageControl(_Mortgagecontrol);
        controlContract = IControl(_controlContract);
        tokenInfo = TokenInfo(_tokenInfo);
        permissions(_token, vaultLenders, VaultRewardsContract, PoolRewardsLenders);
    } 

    modifier validToken(address _token){
        if(!tokenInfo.getToken(_token)){
            revert("Token not support");
        }
        _;
    }

    // ***********************************************************************************************************************

 /// @dev this allow the user to withdraw his rewards if he is a Builder user
    function payBuilderReward(address _token) public nonReentrant validToken(_token) isPaused {
        
        uint256 amountReward = userRewardsBH[msg.sender].rewardPerBuilder;
        if (amountReward == 0) {
            revert("You have no rewards available");
        }
        userRewardsBH[msg.sender].rewardPerBuilder = 0;
        userRewardsBH[msg.sender].lastTimePayBuilder = block.timestamp;
        (,,address VaultRewardsContract) = tokenInfo.getVaultInfo(_token);
        IVaultRewards(VaultRewardsContract).withdraw(amountReward, _token);
       
        handleTransferUser(IERC20(_token), amountReward, msg.sender, userRewardsBH[msg.sender].rewardPerBuilderNFT, address(0));
    }

    /// @dev this allow the user to withdraw his rewards per being a Holder of an NFT.
    function payHolderReward(address _token) public nonReentrant validToken(_token)  isPaused {

        uint256 amountReward = userRewardsBH[msg.sender].rewardPerHolder;
        if (amountReward == 0) {
            revert("You have no rewards available");
        }
        userRewardsBH[msg.sender].rewardPerHolder = 0;
        userRewardsBH[msg.sender].lastTimePayHolder = block.timestamp;
        (,,address VaultRewardsContract) = tokenInfo.getVaultInfo(_token);
        IVaultRewards(VaultRewardsContract).withdraw(amountReward, _token);
        
        handleTransferUser(IERC20(_token), amountReward, msg.sender, userRewardsBH[msg.sender].rewardPerHolderNFT, address(0));
    }

    /// @dev this allow the user to withdraw his rewards per Rent for each collection He holds an NFT
    function payRentReward(address _collection, address _token) public nonReentrant isPaused validToken(_token) {

        checkDebt(_collection, _token);

        uint256 amountRentReward = collectionRewardsRentPerUser[msg.sender][ _collection].rewardPerRent;
        if (amountRentReward == 0) {
            revert("You have no rewards available");
        }
        
        collectionRewardsRentPerUser[msg.sender][_collection].rewardPerRent = 0;
        handleTransferUser(IERC20(_token), amountRentReward, msg.sender, collectionRewardsRentPerUser[msg.sender][ _collection].rewardPerRentNFT, _collection);
    }
    
    ///@dev Funcion para retirar todos los rewards de todas las colecciones en las que el usuario minteo o holdear nfts (buider, holder, rents).
    function payAllRewards(address[] calldata _collections, address _token) public nonReentrant validToken(_token)  isPaused{
        
        uint256 amountRents = 0;
        uint256 amountRentFinal = 0;
        for (uint16 i = 0; i < _collections.length; ) {
            checkDebt(_collections[i], _token);
            amountRents = collectionRewardsRentPerUser[msg.sender][_collections[i]].rewardPerRent;
            if(amountRents > 0){
                amountRentFinal += amountRents;
                collectionRewardsRentPerUser[msg.sender][_collections[i]].rewardPerRent = 0;
                collectionRewardsRentPerUser[msg.sender][_collections[i]].lastTimePayRent = block.timestamp;

                //IVaultRent vaultRent = IVaultRent(collectionToVault[_collections[i]]);
               /*  address vaultRent = tokenInfo.getVaultRent(_collections[i]);
                IVaultRent(vaultRent).withdraw(amountRents, _token); */
            }
            unchecked {
                ++i;
            }
        }

        uint256 amountRewards = userRewardsBH[msg.sender].rewardPerBuilder + userRewardsBH[msg.sender].rewardPerHolder;
        if (amountRewards == 0 && amountRentFinal == 0) {
            revert("No Rewards to claim yet");
        }
        userRewardsBH[msg.sender].rewardPerBuilder = 0;
        userRewardsBH[msg.sender].lastTimePayBuilder = block.timestamp;
        userRewardsBH[msg.sender].rewardPerHolder = 0;
        userRewardsBH[msg.sender].lastTimePayHolder = block.timestamp;
        (,,address VaultRewardsContract) = tokenInfo.getVaultInfo(_token);
        IVaultRewards(VaultRewardsContract).withdraw(amountRewards, _token);

        uint256 finalAmountToClaim = amountRewards + amountRentFinal;
        handleTransferUser(IERC20(_token), finalAmountToClaim,msg.sender, 0, address(0));
    }

   ///@dev Function to check if the user has a Mortgage debt
    function checkDebt(address _collection, address _token) internal {
        uint256 rewardsRent = collectionRewardsRentPerUser[msg.sender][_collection].rewardPerRent;
        uint256[] memory IdMortgagesxCollection = mortgageControl.getMortgagesForWallet(msg.sender, _collection);
        (address vaultLenders, address PoolRewardsLenders,) = tokenInfo.getVaultInfo(_token);
        address VaultRentRewards = tokenInfo.getVaultRent(_collection);
        IVaultRewards(VaultRentRewards).withdraw(rewardsRent, _token);
        if (IdMortgagesxCollection.length > 0) {
            for (uint24 i = 0; i < IdMortgagesxCollection.length; ) {
                MortgageInterest memory mortgage = mortgageControl.getuserToMortgageInterest(msg.sender,IdMortgagesxCollection[i]);
                if (!mortgage.liquidate) {
                    if (mortgage.isMonthlyPaymentDelayed) {
                        if (rewardsRent > 0) {
                            if (rewardsRent >= mortgage.totalToPayOnLiquidation) {
                                rewardsRent -= mortgage.totalToPayOnLiquidation;
                                handleTransferUser(IERC20(_token), mortgage.totalPanoramLiquidation, walletPanoram,0, address(0));
                                IVaultLenders(vaultLenders).deposit(mortgage.amountToVault, _token);
                                IVaultRewards(PoolRewardsLenders).deposit(mortgage.totalPoolLiquidation, _token);

                                if (mortgage.amountToVault >= mortgage.totalDebt) {
                                    mortgage.totalDebt = 0;
                                    mortgageControl.updateMortgageState(IdMortgagesxCollection[i],msg.sender,true);
                                } else {
                                    mortgage.totalDebt -= mortgage.amountToVault;
                                }
                                mortgageControl.resetMortgageInterest(msg.sender,IdMortgagesxCollection[i]);
                                mortgageControl.updateTotalDebtOnAdvancePayment(msg.sender,IdMortgagesxCollection[i],mortgage.totalDebt);
                               
                            } else {
                               if (rewardsRent >= mortgage.totalPoolLiquidation) {
                                    IVaultRewards(PoolRewardsLenders).deposit(mortgage.totalPoolLiquidation, _token);
                                    rewardsRent -= mortgage.totalPoolLiquidation;
                                    mortgage.totalToPayOnLiquidation -= mortgage.totalPoolLiquidation;
                                    mortgage.totalMonthlyPay -= mortgage.amountToPool;
                                    mortgage.totalDelayedMonthlyPay -= mortgage.amountToPoolDelayed;
                                    mortgage.totalPoolLiquidation = 0;
                                    mortgage.amountToPool = 0;
                                    mortgage.amountToPoolDelayed = 0;
                                } else {
                                    if(rewardsRent > 0){
                                        IVaultRewards(PoolRewardsLenders).deposit(rewardsRent, _token);
                                        mortgage.totalPoolLiquidation -= rewardsRent;
                                        mortgage.totalToPayOnLiquidation -= rewardsRent;
                                        
                                        uint256 helpRewardsRentValue = rewardsRent;
                                        if(helpRewardsRentValue >= mortgage.amountToPoolDelayed){
                                            helpRewardsRentValue -= mortgage.amountToPoolDelayed;
                                            mortgage.totalDelayedMonthlyPay -= mortgage.amountToPoolDelayed;
                                            mortgage.amountToPoolDelayed = 0;
                                        } else{
                                            mortgage.amountToPoolDelayed -= helpRewardsRentValue;
                                            mortgage.totalDelayedMonthlyPay -= helpRewardsRentValue;
                                            helpRewardsRentValue = 0;
                                        }

                                        if(helpRewardsRentValue >= mortgage.amountToPool){
                                            helpRewardsRentValue -= mortgage.amountToPool;
                                            mortgage.totalMonthlyPay -= mortgage.amountToPool;
                                            mortgage.amountToPool = 0;
                                        }else{
                                            if(helpRewardsRentValue > 0){
                                                mortgage.amountToPool -= helpRewardsRentValue;
                                                mortgage.totalMonthlyPay -= helpRewardsRentValue;
                                                helpRewardsRentValue = 0;
                                            }
                                        }
                                        rewardsRent = 0;
                                    }
                                } //

                                if(rewardsRent >= mortgage.totalPanoramLiquidation){
                                    handleTransferUser(IERC20(_token), mortgage.totalPanoramLiquidation, walletPanoram,0, address(0));
                                    rewardsRent -= mortgage.totalPanoramLiquidation;
                                    mortgage.totalToPayOnLiquidation -= mortgage.totalPanoramLiquidation;
                                    mortgage.totalMonthlyPay -= mortgage.amountToPanoram;
                                    mortgage.totalDelayedMonthlyPay -= mortgage.amountToPanoramDelayed;
                                    mortgage.totalPanoramLiquidation = 0;
                                    mortgage.amountToPanoram = 0;
                                    mortgage.amountToPanoramDelayed = 0;
                                }else{
                                    if(rewardsRent > 0){
                                        handleTransferUser(IERC20(_token), rewardsRent, walletPanoram,0, address(0));
                                        mortgage.totalPanoramLiquidation -= rewardsRent;
                                        mortgage.totalToPayOnLiquidation -= rewardsRent;

                                        uint256 helpRewardsRentValue = rewardsRent;
                                        if(helpRewardsRentValue >= mortgage.amountToPanoramDelayed){
                                            helpRewardsRentValue -= mortgage.amountToPanoramDelayed;
                                            mortgage.totalDelayedMonthlyPay -= mortgage.amountToPanoramDelayed;
                                            mortgage.amountToPanoramDelayed = 0;
                                        } else{
                                            mortgage.amountToPanoramDelayed -= helpRewardsRentValue;
                                            mortgage.totalDelayedMonthlyPay -= helpRewardsRentValue;
                                            helpRewardsRentValue = 0;
                                        }

                                        if(helpRewardsRentValue >= mortgage.amountToPanoram){
                                            helpRewardsRentValue -= mortgage.amountToPanoram;
                                            mortgage.totalMonthlyPay -= mortgage.amountToPanoram;
                                            mortgage.amountToPanoram = 0;
                                        }else{
                                            if(helpRewardsRentValue > 0){
                                                mortgage.amountToPanoram -= helpRewardsRentValue;
                                                mortgage.totalMonthlyPay -= helpRewardsRentValue;
                                                helpRewardsRentValue = 0;
                                            }
                                        }
                                        rewardsRent = 0;
                                    }
                                }//

                                if(rewardsRent >= mortgage.amountToVault){
                                    IVaultLenders(vaultLenders).deposit(mortgage.amountToVault, _token);
                                    rewardsRent -= mortgage.amountToVault;
                                    if (mortgage.amountToVault >= mortgage.totalDebt) {
                                        mortgage.totalDebt = 0;
                                        mortgageControl.updateMortgageState(IdMortgagesxCollection[i],msg.sender,true);
                                    } else {
                                        mortgage.totalDebt -= mortgage.amountToVault;
                                    }
                                    uint256 capitalPayForMonth = mortgageControl.getCapitalPay(msg.sender, IdMortgagesxCollection[i]);
                                    mortgage.totalToPayOnLiquidation -= mortgage.amountToVault;
                                    mortgage.totalMonthlyPay -= capitalPayForMonth;
                                    mortgage.totalDelayedMonthlyPay -= capitalPayForMonth;
                                    mortgage.amountToVault = 0;
                                }else{
                                    if(rewardsRent > 0){
                                        IVaultLenders(vaultLenders).deposit(rewardsRent, _token);
                                        mortgage.amountToVault -= rewardsRent;
                                        mortgage.totalToPayOnLiquidation -= rewardsRent;
                                        mortgage.totalDelayedMonthlyPay -= rewardsRent;
                                        mortgage.totalMonthlyPay -= rewardsRent;
                                        rewardsRent = 0;
                                    }
                                } //
                                mortgageControl.updateOnPayMortgageInterest(msg.sender,IdMortgagesxCollection[i],mortgage);
                            }
                        }
                    }
                } // if !liquidated
                unchecked {
                    ++i;
                }
            }
            collectionRewardsRentPerUser[msg.sender][_collection].rewardPerRent = rewardsRent;
            collectionRewardsRentPerUser[msg.sender][_collection].lastTimePayRent = block.timestamp;
        }
    }


  /// @dev this function calculate the user Rewards per Builder for all the collections.
    /* CUANDO EL NUMERO DE WALLETS PARA LA QUE SE CALCULARA EL REWARD SEA MUY ALTO, EL AUTOTASK DEBE MANDAR A LLAMAR
     * ESTAS FUNCIONES POR LOTES PARA REDUCIR EL RIESGO DE QUE LA FUNCION SE ACABE EL GAS DURANTE LA EJECUCION DE LA FUNCION
     * Cuando un NFT es liquidado pasa al relay quien sera el dueño de los rewards calculados.
     */
    ///@dev el Autotask debe validar si el monto a repartir es muy bajo y podria dar 0 para que en ese caso no haga el calculo ni el reseteo para que se sumen al siguiente dia y asi calcular solo cuando no dara 0.
    function CalcBuilderRewardsDaily(address[] calldata _walletsUsers,uint256[] calldata _numNFTsMinted, address _token) public onlyDev {
        uint256 wLength = _walletsUsers.length;
        if (wLength != _numNFTsMinted.length) {
            revert("Arrays Mismatch");
        }
        (,,address VaultRewardsContract) = tokenInfo.getVaultInfo(_token);
        uint256 ingresoTemporalDiario = IVaultRewards(VaultRewardsContract).seeDaily();
        if (ingresoTemporalDiario == 0) {
            revert("No Rewards yet");
        }
        //uint256 ingresoDiarioForBuilders = (ingresoTemporalDiario * percentageMinters) / 10000;
        uint256 ingresoDiarioForBuilders = (ingresoTemporalDiario * percentageMinters) / 100;
        uint256 TotalNFTsMinteadosGeneral = controlContract.seeCounter();
        uint256 PayPerNFT = ingresoDiarioForBuilders / TotalNFTsMinteadosGeneral;
        
        for (uint16 i = 0; i < wLength; ) {
            if (_numNFTsMinted[i] != 0) {
                userRewardsBH[_walletsUsers[i]].rewardPerBuilder += _numNFTsMinted[i] * PayPerNFT;
                userRewardsBH[_walletsUsers[i]].rewardPerBuilderNFT = PayPerNFT;
                userRewardsBH[_walletsUsers[i]].lastTimeCalcBuilder = block.timestamp;
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @dev this function calculate the user Rewards per Builder for all the collections.
    function CalcHolderRewardsDaily(address[] calldata _walletsUsers,uint256[] calldata _numNFTsHolder, address _token) public onlyDev {
        uint256 wLength = _walletsUsers.length;
        if (wLength != _numNFTsHolder.length) {
            revert("Array Mismatch");
        }
        (,,address VaultRewardsContract) = tokenInfo.getVaultInfo(_token);
        uint256 ingresoTemporalDiario = IVaultRewards(VaultRewardsContract).seeDaily();
        if (ingresoTemporalDiario == 0) {
            revert("No Rewards yet");
        }
        //uint256 ingresoDiarioForHolders = (ingresoTemporalDiario * percentageHolders) / 10000;
        uint256 ingresoDiarioForHolders = (ingresoTemporalDiario * percentageHolders) / 100;
        uint256 TotalNFTsGeneral = controlContract.seeCounter();
        uint256 PayPerNFT = ingresoDiarioForHolders / TotalNFTsGeneral;

        for (uint16 i = 0; i < wLength; ) {
            if (_numNFTsHolder[i] != 0) {
                userRewardsBH[_walletsUsers[i]].rewardPerHolder += _numNFTsHolder[i] * PayPerNFT;
                userRewardsBH[_walletsUsers[i]].rewardPerHolderNFT = PayPerNFT;
                //uint256 PayPerNFT = ingresoDiarioForHolders * _numNFTsHolder[i];
                //userRewardsBH[_walletsUsers[i]].rewardPerHolder += PayPerNFT / TotalNFTsGeneral;
                userRewardsBH[_walletsUsers[i]].lastTimeCalcHolder = block.timestamp;
            }
            unchecked {
                ++i;
            }
        }
    }

    // funcion para calcular los rewards por renta el autotask la llamara cada 30 dias.
    function CalcRentRewardsForCollection(address _collection,address[] calldata _walletsUsers,uint256[] calldata _numNFTsHolder) public onlyDev {
        uint256 wLength = _walletsUsers.length;
        if (wLength != _numNFTsHolder.length) {
            revert("Array Mismatch");
        }
        ILazyNFT CollectionContract = ILazyNFT(_collection);
        address vaultRentRewards = tokenInfo.getVaultRent(_collection);
        uint256 monthlyRentIncome = IVaultRent(vaultRentRewards).seeQuarter();
        // LA VARIABLE DE QUATER DEL VAULT SE DEBE RESETEAR UNA VEZ AL MES
        if (monthlyRentIncome == 0) {
            revert("No Monthly Rental Income Yet");
        }
        uint256 dailyIncome = monthlyRentIncome / 30;
        uint256 totalNFtsxCollection = CollectionContract.totalSupply();
       // uint256 totalNFtsxCollection = CollectionContract.maxSupply();
        uint256 PayPerNFT = dailyIncome / totalNFtsxCollection;

        for (uint16 i = 0; i < wLength; ) {
            if (_numNFTsHolder[i] != 0) {
                collectionRewardsRentPerUser[_walletsUsers[i]][_collection].rewardPerRent += _numNFTsHolder[i] * PayPerNFT;
                collectionRewardsRentPerUser[_walletsUsers[i]][_collection].rewardPerRentNFT = PayPerNFT;
                collectionRewardsRentPerUser[_walletsUsers[i]][_collection].lastTimeCalcRent = block.timestamp;
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @dev this function is for obtain the user info struct per wallet
    function getRewardsPerUserRent(address _walletUser, address _Collection) public view returns (uint256,uint256,uint256,uint256){
        UserRewardsRent memory rent;
        return (rent.rewardPerRent = collectionRewardsRentPerUser[_walletUser][_Collection].rewardPerRent,
        rent.lastTimePayRent = collectionRewardsRentPerUser[_walletUser][_Collection].lastTimePayRent,
        rent.lastTimeCalcRent = collectionRewardsRentPerUser[_walletUser][_Collection].lastTimeCalcRent,
        rent.rewardPerRent = collectionRewardsRentPerUser[_walletUser][_Collection].rewardPerRentNFT);
    }

    function getRewardsPerUserBH(address _walletUser) public view returns (uint256,uint256,uint256,uint256,uint256,uint256){
        UserRewards memory locals;
        return (locals.rewardPerBuilder = userRewardsBH[_walletUser].rewardPerBuilder,
        locals.lastTimePayBuilder = userRewardsBH[_walletUser].lastTimePayBuilder,
        locals.lastTimeCalcBuilder = userRewardsBH[_walletUser].lastTimeCalcBuilder,
        locals.rewardPerHolder = userRewardsBH[_walletUser].rewardPerHolder,
        locals.lastTimePayHolder = userRewardsBH[_walletUser].lastTimePayHolder,
        locals.lastTimeCalcHolder = userRewardsBH[_walletUser].lastTimeCalcHolder
        );
    }

    function updateControl(address _newControl) public onlyDev {
        controlContract = IControl(_newControl);
        
    }

    function updateMortgageControl(address _newMcontrol) public onlyDev {
        mortgageControl = IMortgageControl(_newMcontrol);
    }

    function updateTokenInfo(address _tokenInfo) public {
        if (!hasRole(DEV_ROLE, msg.sender)) {
             revert("have no dev role");
        }
        tokenInfo = TokenInfo(_tokenInfo);
    }

    function permissions(address _token, address _lender, address _rewards, address lendersRewards) public onlyDev validToken(_token) {
        IERC20(_token).approve(_lender, 2**255);
        IERC20(_token).approve(_rewards, 2**255);
        IERC20(_token).approve(lendersRewards, 2**255);
    }


    // **** FUNCIONES SOLO PARA DESARROLLO.
   /*  function clearRewardsRent(address _wallet, address _collection) public {
        collectionRewardsRentPerUser[_wallet][_collection].rewardPerRent = 0;
        collectionRewardsRentPerUser[_wallet][_collection].lastTimePayRent = 0;
    }

    function clearRewardsBH(address _wallet) public {
        userRewardsBH[_wallet].rewardPerBuilder = 0;
        userRewardsBH[_wallet].lastTimePayBuilder = 0;
        userRewardsBH[_wallet].rewardPerHolder = 0;
        userRewardsBH[_wallet].lastTimePayHolder = 0;
    } */
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

interface IControl {

   function getNFTInfo(address _collection, uint256 _id)
        external
        view
        returns (
            address,
            uint256,
            address,
            uint32
        );

    function getNFTTotal(address _wallet) external view returns (uint256 _total);

    function getNFTMinted(address _wallet) external view returns (uint256 _minted);

    function getNFTQuantity(address _wallet, address _collection)external view returns (uint256 _quantity);

    function addRegistry(address _collection, uint256 _nftId, address _wallet,uint32 _timestamp) external;

    function removeRegistry(address _collection, uint256 _nftId) external;

    function addQuantity(address _wallet,address _collection,uint256 _amount) external;

    function removeQuantity(address _wallet,address _collection, uint256 _amount) external;

    function addMinted(address _wallet,uint256 _amount) external;

    function addCounter() external;

    function seeCounter() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.10;

interface IVaultRewards {
    function deposit(uint256 _amount,  address _token) external;

    function withdraw(uint256 amount, address _token) external;

    function withdrawAll() external;

    function seeDaily() external view returns (uint256 tempRewards);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.10;

interface IVaultRent {
    function deposit(uint256 _amount,  address _token) external;

    function withdraw(uint256 amount, address _token) external;

    function withdrawAll() external;

    function seeQuarter() external view returns (uint256 tempRewards);
    
    function Name() external view returns (string memory _name);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract HelperRewardsContract is ReentrancyGuard, AccessControl{

   // Porcentajes en referencia a base 10 mil
   /*  uint16 public percentageHolders = 7000;
    uint16 public percentageMinters = 3000; */
    uint16 public percentageHolders = 70;
    uint16 public percentageMinters = 30;
    bool internal paused = false;

    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    //Binance relayer 0x59C1E897f0A87a05B2B6f960dE5090485f86dd3D;
   address internal relayAddress = 0x988F94C0Ef61815AacD775789Af297713408D3B8;
    //Change to mainnet multisig-wallet
   address public walletPanoram = 0x526324c87e3e44630971fd2f6d9D69f3914e01DA; 

    
    event withdrawSuccess(address indexed walletUser, uint256 amountReward, uint256 payPerNFT, address collection);

    modifier onlyDev() {
        if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("Not enough Permissions");
        }
        _;
    }

    modifier isPaused(){
        if(paused){
            revert("contract paused");
        }
        _;
    }
    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x526324c87e3e44630971fd2f6d9D69f3914e01DA);
        _setupRole(DEV_ROLE, 0x526324c87e3e44630971fd2f6d9D69f3914e01DA);
        _setupRole(DEV_ROLE, relayAddress);
        _setupRole(DEV_ROLE, msg.sender);
    }

    function handleTransferUser(IERC20 _token, uint256 _amount, address _wallet, uint256 _payPerNFT, address _collection) internal {   
        if(!_token.transfer(_wallet, _amount)){
                    revert("transfer fail");
        }
        emit withdrawSuccess(_wallet, _amount, _payPerNFT, _collection);
    } 

    ///@dev funciones para actualizar los porcentajes repartidos de los fees.
    // Estas funciones tienes que dar una suma 100% en total porque ya se tiene separado el 50% de panoram en multisign.
    function updatePercentageHolders(uint8 _newPercentage) public onlyDev {
        percentageHolders = _newPercentage;
    }

    function updatePercentageMinters(uint8 _newPercentage) public onlyDev {
        percentageMinters = _newPercentage;
    }

  function updatePaused(bool _Status) public {
        if (!hasRole(DEV_ROLE, msg.sender)) {
             revert("have no dev role");
        }
        paused = _Status;
    }

    function updatePanoramWallet(address _newWalletPanoram) public onlyDev {
            walletPanoram = _newWalletPanoram;
    }

    function updateRelayer(address _relayer) public onlyDev {
            relayAddress = _relayer;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.10;

interface IVaultLenders {
    function deposit(uint256,address) external;

    function depositCapital(uint256,address) external;

    function withdraw(uint256,address) external;

    function withdrawAll() external;

    function totalSupply() external view returns (uint256);

    function getBorrows() external view returns(uint256 borrows);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMortgageInterest {
    struct MortgageInterest {
        uint256 totalDebt; // para guardar lo que adeuda el cliente despues de cada pago
        uint256 totalMonthlyPay; // total a pagar en pago puntual 100
        uint256 amountToPanoram; // cantidad que se ira a la wallet de Panoram
        uint256 amountToPool; // cantidad que se ira al Pool de rewards
        uint256 amountToVault; // cantidad que se regresa al vault de lenders
        uint256 totalDelayedMonthlyPay; // total a pagar en caso de ser pago moratorio, incluye pagar las cuotas atrasadas
        uint256 amountToPanoramDelayed; // cantidad que se ira a la wallet de Panoram
        uint256 amountToPoolDelayed; // cantidad que se ira al Pool de rewards
        uint256 totalToPayOnLiquidation; // sumar los 3 meses con los interes
        uint256 totalPoolLiquidation; // intereses al pool en liquidation
        uint256 totalPanoramLiquidation; // total a pagar de intereses a panoram en los 3 meses que no pago.
        uint256 lastTimePayment; // guardamos la fecha de su ultimo pago
        uint256 lastTimeCalc; // la ultima vez que se calculo sus interes: para evitar calcularle 2 veces el mismo dia
        uint8 strikes; // cuando sean 2 se pasa a liquidacion. Resetear estas variables cuando se haga el pago
        bool isMonthlyPaymentPayed; // validar si ya hizo el pago mensual
        bool isMonthlyPaymentDelayed; // validar si el pago es moratorio
        bool liquidate; // true si el credito se liquido, se liquida cuando el user tiene 3 meses sin pagar
    }

    ///@notice structure and mapping that keeps track of mortgage
    struct Information {
        address collection;
        uint256 nftId;
        address wrapContract;
        uint256 loan; // total prestado
        uint256 downPay;
        uint256 price;
        uint256 startDate;
        uint256 period; //months
        uint8 interestrate; //interest percentage diario
        uint256 payCounter; //Start in zero
        bool isPay; //default is false
        bool mortgageAgain; //default is false
        uint256 linkId; //link to the new mortgage
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
interface ILazyNFT is IERC165{
    
    function redeem(
        address _redeem,
        uint256 _amount
    ) external returns (uint256);

    function preSale(
        address _redeem,
        uint256 _amount
    ) external returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function tokenURI(uint256 tokenId) external view returns (string memory base);

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory, uint256 _length);

    function totalSupply() external view returns (uint256);

    function maxSupply() external view returns (uint256);
     
    function getPrice() external view returns (uint256);
    
    function getPresale() external view returns (uint256);

    function getPresaleStatus() external view returns (bool);

    function nftValuation() external view returns (uint256 _nftValuation);

    function getValuation() external view returns (uint256 _valuation);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.10;

import "./IMortgageInterest.sol";

interface IMortgageControl is IMortgageInterest {

    function addIdInfo(uint256 id, address wallet) external;

    function updateCapitalPay(uint256 id, address wallet, uint256 _newDebt) external; 

    function getTotalMortgages() external view returns (uint256);

    function getCapitalPay(address _user, uint256 _mortgageId) external view returns(uint256 _capitalPay);

    function getDebtInfo(address _user, uint256 _mortgageId) external view returns(uint256,uint256,uint256);

    function mortgageStatuts(address _user, uint256 _mortgageId) external view returns (bool _isPay);

    function getMortgageLiquidationStatus(address _user, uint256 _mortgageId) external view returns(bool _status);

    function mortgageLink(address _user, uint256 _mortgageId) external view returns (bool _mortgageAgain, uint256 _linkId);

    function getMortgagesForWallet(address _wallet, address _collection)
        external
        view
        returns (uint256[] memory _idMortgagesForCollection);

    function getuserToMortgageInterest(address _wallet, uint256 _IdMortgage)
        external
        view
        returns (MortgageInterest memory);

    // Get FrontEnd Data
    function getFrontMortgageData(address _wallet, uint256 _IdMortage)
        external
        view
        returns (
            uint256 totalDebt,
            uint256 totalMonthlyPay,
            uint256 totalDelayedMonthlyPay,
            uint256 totalToPayOnLiquidation,
            uint256 lastTimePayment,
            bool isMonthlyPaymentPayed,
            bool isMonthlyPaymentDelayed,
            bool liquidate
        );

    function getIdInfo(uint256 id) external view returns (address _user);

    function getInterestRate() external view returns(uint64 _interest);

    function getMortgageId(address _collection, uint256 _nftId) external view returns(uint256 _mortgageId);

    function getStartDate(address _wallet, uint256 _mortgageID) external view returns(uint256);

    function getUserInfo(address _user, uint256 _mortgageId)
        external
        view
        returns (
            address,
            uint256,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            bool,
            uint256
        );

    function getMortgageStatus(address _user, uint256 _mortgageId) external view returns(bool _status);

    function addMortgageId(address _collection, uint256 _nftId, uint256 _loanId) external;

    function eraseMortgageId(address _collection, uint256 _nftId) external;

    function addRegistry(uint256 id, address wallet, address _collection, address _wrapContract,uint256 _nftId, uint256 _loan,uint256 _downPay,
    uint256 _price,uint256 _startDate,uint256 _period ) external; 

    function updateMortgageLink(
        uint256 oldId,
        uint256 newId,
        address wallet,
        uint256 _loan,
        uint256 _downPay,
        uint256 _startDate,
        uint256 _period,
        bool _mortageState
    ) external;

    function updateMortgageState(
        uint256 id,
        address wallet,
        bool _state
    ) external;

    function updateMortgagePayment(uint256 id, address wallet) external;

    function addNormalMorgateInterestData(
        address _wallet,
        uint256 _idMortgage,
        MortgageInterest memory _mortgage
    ) external;

    function resetMortgageInterest(address _wallet, uint256 _idMortgage) external;
    
    function resetDebt(address _wallet, uint256 _idMortgage) external;
    
    function updateLastTimeCalc(address _wallet, uint256 _idMortgage,uint256 _lastTimeCalc) external;
    
    function addDelayedMorgateInterestData(
        address _wallet,
        uint256 _idMortgage,
        MortgageInterest memory _mortgage
    ) external;

    function updateOnPayMortgageInterest(
        address _wallet,
        uint256 _idMortgage,
        MortgageInterest memory mort
    ) external;

    function updateTotalDebtOnAdvancePayment(
        address _wallet,
        uint256 _idMortgage,
        uint256 _totalDebt
    ) external;

    function updateLastTimePayment(address _wallet, uint256 _idMortgage,uint256 _lastPayment) external;
    
    function getLastTimePayment(address _wallet, uint256 _idMortgage) external view returns(uint256);


    ///@dev only for test erase in production
    function getTestInfo(address _user, uint256 _mortgageId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract TokenInfo is AccessControl {

    ///@dev developer role created
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    
    modifier onlydev() {
         if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("have no dev role");
        }
        _;
    }

    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEV_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x526324c87e3e44630971fd2f6d9D69f3914e01DA);
        _setupRole(DEV_ROLE, 0x526324c87e3e44630971fd2f6d9D69f3914e01DA);
        _setupRole(DEV_ROLE, 0x988F94C0Ef61815AacD775789Af297713408D3B8);
    }

    struct Vaults{
        address lender;
        address lenderRewards;
        address rewards;
    }
    //registration and control of approved tokens
    mapping(address => bool) internal tokens;
    //save the token contract and the vault for it
    mapping(address => Vaults) internal vaultsInfo;
    //save the collection contract and the rental vault contract to be used for each collection
    mapping(address => address) internal collectionToVault;

    function addToken(address _token) public onlydev {
        tokens[_token] = true;
    }

    function removeToken(address _token) public onlydev {
        tokens[_token] = false;
    }

    function getToken(address _token) public view returns(bool _ok){
        return tokens[_token];
    }

    function addVaultRegistry(address _token, address _lender,address _lenderRewards,address _rewards) public onlydev  {
        vaultsInfo[_token].lender = _lender;
        vaultsInfo[_token].lenderRewards = _lenderRewards;
        vaultsInfo[_token].rewards = _rewards;
    }

    function removeVaultRegistry(address _token) public onlydev  {
        vaultsInfo[_token].lender = address(0);
        vaultsInfo[_token].lenderRewards = address(0);
        vaultsInfo[_token].rewards = address(0);
    }

    function getVaultInfo(address _token) public view returns(address _lender, address _lenderRewards,address _rewards){
        return ( vaultsInfo[_token].lender,
        vaultsInfo[_token].lenderRewards,
        vaultsInfo[_token].rewards);
    }

    function addVaultRent(address _collection, address _vault) public onlydev {
        collectionToVault[_collection] = _vault;
    }

    function removeVaultRent(address _collection) public onlydev {
        collectionToVault[_collection] = address(0);
    }

    function getVaultRent(address _collection) public view returns(address _vault){
        return collectionToVault[_collection];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
interface IERC165 {
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