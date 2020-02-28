pragma solidity 0.6.0;

///@title smart contract crowdsale 
///@author widad khatiri
///@notice : a basic crowdsale for ERC20 Token
//importation de la library OpenZeppelin 
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol';
//importation du smart contract du Token carCoin
import "./carCoin.sol";


contract crowdsale{
    
    using SafeMath for uint;
    
    uint256 public startTime; ///la date de debut
    uint256 public deadline; ///la date du fin
    uint256 public ccPrice; ///le prix d'un' token
    uint256 public objectivCc; ///minimum pour atteindre l'objectif d'investisement
    uint256 public investReceived; ///total ether recus par les investisseurs
    uint256 public investRefunded; ///total ether remboursé
    
    mapping(address=>uint256) public investmentAmt; ///le montont en ether
    
    bool public isFinalized; ///pour savoir si les ventes sont fini
    bool public isRefundingAllowed;///pour verifier la possibilite de remboursement
    bool public objectiveReached; ///pour verifier c'est le contrat a atteint les objectifs attendus
    
    address payable public owner; ///le compte administrateur 
    CarCoin public carCoin; ///Token CarCoin
    
    event ObjectiveCCReached(address owner,uint256 investReceived);
     event LogInvestment(address indexed investor, uint256 value);
    event LogTokenAssignment(address indexed investor, uint256 numTokens);
    event Refund(address investor, uint256 value);
    
    ///constructor qui prend en parametre le teken et le prix de notre token la date de debut et de fin de la vente
    constructor(uint256 _startTime, uint256 _deadline, uint256 _ccPrice, uint256 _minCc)public
    {
        ///je verifie si la date de debut est superieur à la date actuel et que la date de fin superieur à la date de debut de la vente des carCoin(token)
       require(_startTime>=now); 
       require(_deadline>=_startTime);
       ///je verifie si le prix et l'objectif est differents de 0
        require(_ccPrice!=0); 
       require(_minCc!=0);
       
       startTime=_startTime;
       deadline=_deadline ;
       ccPrice=_ccPrice;
       objectivCc=_minCc;
       
       carCoin=new CarCoin(); ///iinstance du Token : CarCoin
       isFinalized=false; 
       isRefundingAllowed=false;
       owner=msg.sender; ///owner la personne qui deploie le contrat
    }
    
///@notice fonction permet d'acheter des Tokens
///ne peut etre appeler que durant la periode des ventes grace au modifier onlyInTime
///verifer la valeur envoyer par l'investisseur par l'intermediaire du modifier isValidInvestment
function bayCC() public payable isValidInvestment(msg.value) onlyInTime {
    address investor = msg.sender;
    uint256 investment = msg.value;
    
    investmentAmt[investor] = investmentAmt[investor].add(investment);
     investReceived=investReceived.add(investment);
     
    assignTokens(investor, investment);//transfer les token à l'investisseur
    emit LogInvestment(investor, investment); 
}

///@notice
///@param fonction prend en param l'adresse de la personne qui a acheter les tokens et le montant
///fait appel à une fonction interne 
///et a la fonction transfer pour le transfer des token
function assignTokens(address _beneficiary, 
    uint256 _investment) internal {

    uint256 _numberOfTokens = 
       calculateNumberOfTokens(_investment);
    
    carCoin.transfer(_beneficiary, 
       _numberOfTokens);
}

///@notice fonction interne permet le calcul de nombres de Tokens 
///@param _investment correspond au montant de l'investisement
///@return  la fonction retourne le nombre de Token
function calculateNumberOfTokens(uint256 _investment) 
    internal view returns (uint256) {
    return  _investment= _investment.div(ccPrice); //on devise la valeur envoye en eth sur le prix d'un token pour avoir le nombre de token 
}

///@notice modifier pour verifier s'il s'agit bien de l'administrateur
modifier onlyOwner {
   require(msg.sender == owner);

    _;
}

///@notice modifier pour verifier si le montant envoyé est different de 0
modifier isValidInvestment(uint256 _investment){
    require( _investment != 0);
    _;
}
///@notice modifier pour verifier qu'on est bien dans la duree des ventes 
modifier onlyInTime() {
        require(now >= startTime && now <= deadline);
        _;
    }
    
///@notice modifier pour verifier si la deadline est depassé
  modifier afterDeadline() {
        require(now >= deadline);
        _;
    }

///@notice fonction pour verifier si notre contrat a reussi de atteindre l'objectif ou non
function checkGoalReached() onlyOwner afterDeadline public{
     require(isFinalized);
    if(investReceived >= objectivCc){
         objectiveReached=true;
       emit ObjectiveCCReached(owner,investReceived);
    }else{
      isRefundingAllowed=true;
      isFinalized=true;
   }
}

///@notice fonction pour permettre de rembourser les investisseurs en cas d'echec
function refund() public afterDeadline {
     require(!isRefundingAllowed);
    address payable investor = msg.sender;
     uint256 investment = investmentAmt[investor];
        
     require(investment != 0);
    investmentAmt[investor] = 0;
    investRefunded=investRefunded.add(investment);
        
    emit Refund(msg.sender, investment);
    investor.transfer(investment);
}        

///@notice fonction pour envoyer les fonds à l'admin en cas de succes
function endSale() public onlyOwner afterDeadline{
    require(!isRefundingAllowed);
    owner.transfer(investReceived);
}
    
}