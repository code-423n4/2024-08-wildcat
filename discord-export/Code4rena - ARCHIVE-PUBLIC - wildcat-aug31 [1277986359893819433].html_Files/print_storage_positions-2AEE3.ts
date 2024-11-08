import { existsSync, readdirSync, statSync } from "fs";
import path from "path";
import { parseArgs } from "node:util";

// Before using, make sure foundry.toml has `extra_output=["storageLayout"]`
//
// Script to print out the storage positions of a struct in a Solidity contract.
// CLI args:
// --contract <contract name>
// If the contract is in a file with the same name, you can just use the contract name.
// Otherwise, use the name-path format from foundry, i.e. `./src/ContractFile.sol:Contract`
// --struct <struct name>

const ProjectRoot = path.join(__dirname, "..");
const ForgeOutDir = path.join(ProjectRoot, "out");

const args = parseArgs({
  options: {
    contract: {
      type: "string",
      short: "c",
      default: "WildcatMarket",
    },
    struct: {
      type: "string",
      short: "s",
      default: "MarketState",
    },
  },
});

function findFileNameInDirectory(
  directory: string,
  fileName: string
): string[] {
  const members = readdirSync(directory).map((file) =>
    path.join(directory, file)
  );
  const found = [];
  // Check each member of the directory, if it is a file check if it is the file we are looking
  // for, if it is a directory, recursively search it for the file we are looking
  for (const member of members) {
    if (statSync(member).isFile()) {
      if (path.basename(member) === fileName) {
        found.push(member);
      }
    } else {
      const foundInMember = findFileNameInDirectory(member, fileName);
      found.push(...foundInMember);
    }
  }
  return found;
}

function getContractNamePath(contract: string) {
  let contractPath: string;
  let contractName: string;
  if (contract.includes(":")) {
    const [filePath, name] = contract.split(":");
    contractPath = path.resolve(filePath);
    contractName = name;
  } else if (contract.includes(".sol")) {
    const name = path.parse(contract).name;
    contractPath = path.resolve(contract);
    contractName = name;
  } else {
    contractPath = `${path.join(ProjectRoot, `src/${contract}.sol`)}`;
    contractName = contract;
  }
  if (existsSync(contractPath)) {
    return `${contractPath}:${contractName}`;
  } else {
    const found = findFileNameInDirectory(
      path.join(ProjectRoot, "src"),
      path.basename(contractPath)
    );
    if (found.length === 0) {
      throw Error(`Contract not found: ${contract}`);
    } else if (found.length > 1) {
      throw Error(`Multiple files found for ${contract}: ${found.join(", ")}`);
    } else {
      return `${found[0]}:${contractName}`;
    }
  }
}

function findForgeOutputJsonFile(contract: string) {
  const [contractPath, name] = contract.split(":");
  const pathComponents = contractPath.split(path.sep);
  let pathCandidate = '';

  while (pathComponents.length) {
    pathCandidate = path.join(pathComponents.pop() as string, pathCandidate);
    const forgeJsonPath = path.join(ForgeOutDir, pathCandidate, `${name}.json`);
    if (existsSync(forgeJsonPath)) {
      return forgeJsonPath;
    }
  }
  throw Error(`Failed to find forge output JSON for ${contract}`);
}

function handleInputContractPath(contract: string, struct: string) {
  const contractNamePath = getContractNamePath(contract);
  const [absolutePath, contractName] = contractNamePath.split(":");
  
  if (!existsSync(absolutePath)) {
    throw Error(`Contract not found: ${absolutePath}`);
  }
  const forgeOutputJsonFile = findForgeOutputJsonFile(contractNamePath);
  const forgeOutput = require(forgeOutputJsonFile);
  console.log(`Found forge output: ${forgeOutputJsonFile}`);
  const types = forgeOutput?.storageLayout?.types;
  if (!types) {
    throw Error(
      `No storage layout found for ${contractNamePath}. Make sure it is enabled in foundry.toml`
    );
  }
  const type: any = Object.values(types).find(
    (type: any) => type.label.toLowerCase() === `struct ${struct.toLowerCase()}`
  );
  if (!type) {
    throw Error(`Struct ${struct} not found in ${contract}`);
  }

  const members = type.members;

  const parametersBySlot: Record<
    string,
    { label: string; offsetFromLeft: number; end: number }[]
  > = {};
  // Solc's `storageLayout` output uses offsets that are from the right side of the slot.
  // To print the members in the right order, we reverse the order of the members of a slot
  // and then convert their offsets to be relative to the left side of the slot.
  for (const member of members) {
    let { slot, offset: offsetFromRight, label, type } = member;
    type = type.replace("t_", "");
    const length =
      type === "bool"
        ? 1
        : type.startsWith("uint")
        ? parseInt(type.replace("uint", "")) / 8
        : undefined;
    if (!length) continue;
    const offsetFromLeft = 32 - offsetFromRight - length;
    const end = offsetFromLeft + length;
    if (!parametersBySlot[slot]) parametersBySlot[slot] = [];
    parametersBySlot[slot].push({ label, offsetFromLeft, end });
  }
  console.log(`Struct ${struct} in ${contractName}`);
  console.log(`Members:`);
  for (const slot in parametersBySlot) {
    const members = parametersBySlot[slot].reverse();
    for (const { label, offsetFromLeft, end } of members) {
      console.log(`  Slot ${slot} @ [${offsetFromLeft}:${end}] | ${label}`);
    }
  }
}

handleInputContractPath(args.values.contract!, args.values.struct!);
