// Hardhat Ignition deployment module for BeamVest
// Learn more at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("BeamVestModule", (m) => {
  const beamVest = m.contract("BeamVest");
  return { beamVest };
});
