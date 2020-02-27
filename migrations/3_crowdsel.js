const crowdsel = artifacts.require("crowdsel");

module.exports = function(deployer) {
  deployer.deploy(crowdsel);
};
