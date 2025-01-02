import { ethers, run, network } from "hardhat";

// Configuration
const CONFIG = {
  days: 7,
  ethPrice: BigInt(2000) * (BigInt(10) ** BigInt(18)),
  blockConfirmations: 6,
  sepoliaChainId: 11155111
} as const;

async function deployContract(duration: number, price: bigint) {
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying with account: ${await deployer.getAddress()}`);

  const SimpleFundraiser = await ethers.getContractFactory("SimpleFundraiser");
  const fundraiser = await SimpleFundraiser.deploy(duration, price);
  await fundraiser.waitForDeployment();

  return fundraiser;
}

async function verifyContract(
  address: string,
  constructorArgs: [number, bigint]
) {
  try {
    await run("verify:verify", {
      address,
      constructorArguments: constructorArgs,
    });
    console.log("Verified successfully");
  } catch (error: any) {
    if (error.message.toLowerCase().includes("already verified")) {
      console.log("Already verified!");
    } else {
      throw error;
    }
  }
}

async function main() {
  try {
    // Calculate duration in seconds
    const duration = CONFIG.days * 24 * 60 * 60;

    // Deploy
    const fundraiser = await deployContract(duration, CONFIG.ethPrice);
    const contractAddress = await fundraiser.getAddress();
    console.log(`Deployed to: ${contractAddress}`);

    // Verify if on Sepolia
    if (network.config.chainId === CONFIG.sepoliaChainId) {
      if (!process.env.ETHERSCAN_API_KEY) {
        console.warn("Skipping verification: ETHERSCAN_API_KEY not found");
        return;
      }

      console.log("Starting contract verification process...");
      console.log(`Waiting for ${CONFIG.blockConfirmations} block confirmations...`);

      const deployTx = fundraiser.deploymentTransaction();
      if (!deployTx) {
        throw new Error("Deployment transaction not found");
      }

      try {
        await deployTx.wait(CONFIG.blockConfirmations);
        console.log("Block confirmations received");

        await verifyContract(contractAddress, [duration, CONFIG.ethPrice]);
      } catch (error) {
        console.error("Verification process failed:", error);
        throw error;
      }
    } else {
      console.log("Skipping verification: Not on Sepolia network");
    }
  } catch (error) {
    console.error("Deployment failed:", error);
    process.exitCode = 1;
  }
}

main();
