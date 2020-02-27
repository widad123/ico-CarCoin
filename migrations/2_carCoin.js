const carCoin = artifacts.require("carCoin");

module.exports = function(deployer) {
  deployer.deploy(carCoin);
};
