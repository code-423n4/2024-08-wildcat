// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { Vm as ForgeVM } from 'forge-std/Vm.sol';
import { console } from 'forge-std/console.sol';
import 'solady/utils/LibString.sol';

string constant bashFilePath = 'deployments/write-standard-json.sh';
import 'src/libraries/LibStoredInitCode.sol';

using LibString for string;
using LibString for address;
using LibString for bytes;
using JsonUtil for Json;
using JsonUtil for Deployments global;
using LibDeployment for Deployments global;
using LibDeployment for ContractArtifact global;

ForgeVM constant forgeVm = ForgeVM(address(uint160(uint256(keccak256('hevm cheat code')))));

/**
 * @param dir               The directory where the deployments will be saved.
 *                          `deployments/<network-name>`
 * @param forgeOutDir       The forge output directory.
 * @param filePath          The path to the deployments.json file.
 * @param deployments       The deployments json object.
 * @param privateKeyVarName The name of the environment variable that
 *                          holds the private key.
 * @param artifacts         The newly created deployment artifacts.
 */
struct Deployments {
  string dir;
  string forgeOutDir;
  string filePath;
  Json deployments;
  string privateKeyVarName;
  ContractArtifact[] artifacts;
}

/**
 * @param namePath        The name or namepath of the contract to deploy,
 *                        e.g. `Counter` or `src/Counter.sol:Counter`
 * @param name            Name of the contract, e.g. Counter
 * @param artifactDir     The directory where the deployment artifact will be saved
 * @param constructorArgs The abi-encoded constructor arguments for the deployment
 * @param deployment      The address of the deployment
 */
struct ContractArtifact {
  string namePath;
  /** The name of the contract */
  string name;
  string artifactDir;
  bytes constructorArgs;
  address deployment;
}

struct Json {
  string id;
  string serialized;
}

// ========================================================================== //
//                         Deployments Initialization                         //
// ========================================================================== //

/**
 * @dev Get the deployments object for a given network.
 *      If the deployments directory does not exist, it will be created
 */
function getDeploymentsForNetwork(
  string memory networkName
) returns (Deployments memory deployments) {
  checkFfiEnabled();
  deployments.dir = pathJoin('deployments', networkName);
  checkDirectoryExistsAndAccessible(deployments.dir, true);
  deployments.filePath = pathJoin(deployments.dir, 'deployments.json');
  deployments.forgeOutDir = getForgeOutputDirectory();
  checkDirectoryExistsAndAccessible(deployments.forgeOutDir, false);

  if (forgeVm.exists(deployments.filePath)) {
    console.log(string.concat('Reading deployments from ', deployments.filePath));
    deployments.deployments = JsonUtil.create(forgeVm.readFile(deployments.filePath));
  } else {
    console.log(
      string.concat(
        'No deployments found at ',
        deployments.filePath,
        '. Creating new deployments file'
      )
    );
    deployments.deployments = JsonUtil.create();
  }
}

function getDeployments() returns (Deployments memory deployments) {
  string memory networkName = getNetworkName();
  deployments = getDeploymentsForNetwork(networkName);
  deployments.privateKeyVarName = join('PVT_KEY', networkName.upper(), '_');
}

/// @title Deployer
/// @author d1ll0n
/// @dev Library for managing deployments for Forge scripts.
///
///  Provides functions for deploying contracts, retrieving deployments and saving
///  deployment artifacts that include compiler output, standard input json and
///  constructor args.
///
/// ===================================================================================
///                              Setup Instructions
/// ===================================================================================
///
/// 1. Grant access to the `deployments` directory and to the forge output directory.
///    Add this to foundry.toml:
///         fs_permissions = [
///             { access = "read-write", path = "./deployments/"},
///             { access = "read-write", path = "./out/"},
///         ]
///    If your output directory is different, replace `./out/` with the correct path and
///    change the `outputDir` constant in this file.
///
/// 2. Enable FFI so that the script can rush bash commands. This is used to generate
///    the standard input json for the contract deployment.
///    Add `ffi=true` to the foundry.toml file.
///
///
library LibDeployment {
  using LibDeployment for Json;
  using LibDeployment for ContractArtifact[];

  // ========================================================================== //
  //                                 Deployments                                //
  // ========================================================================== //

  function getOrDeployInitcodeStorage(
    Deployments memory self,
    string memory namePath,
    bytes memory creationCode,
    bool overrideExisting
  ) internal returns (address deployment, bool didDeploy) {
    ContractArtifact memory artifact = parseContractNamePath(namePath);
    string memory label = string.concat(artifact.name, '_initCodeStorage');
    if (overrideExisting || !self.has(label)) {
      deployment = self.broadcastDeployInitcode(creationCode);

      artifact.deployment = deployment;

      self.set(label, deployment);
      self.pushArtifact(artifact);
      didDeploy = true;
    } else {
      deployment = self.get(label);
      console.log(string.concat('Found ', namePath, ' at'), deployment);
    }
  }

  function addArtifactWithoutDeploying(
    Deployments memory self,
    string memory customLabel,
    string memory namePath,
    address deploymentAddress,
    bytes memory constructorArgs
  ) internal {
    ContractArtifact memory artifact = parseContractNamePath(namePath);

    artifact.deployment = deploymentAddress;
    artifact.constructorArgs = constructorArgs;

    self.set(customLabel, deploymentAddress);
    self.pushArtifact(artifact);
  }

  /**
   * @dev Deploy a contract or retrieve an existing deployment.
   *
   *      If the contract has already been deployed and `overrideExisting`
   *      is false, the contract address will be retrieved from the existing
   *      deployments. If the contract has not been deployed, or
   *      if `overrideExisting` is true, a new contract will be deployed and
   *      the deployment address will be saved to the deployments.json file.
   *
   *      If the contract has not been deployed or if `overrideExisting`
   *      is true, the contract will be deployed and the deployment address
   *      will be saved to the deployments.json file.
   *
   *      Additionally, the standard input json will be saved to the deployment
   *      artifact directory.
   *
   *
   *
   * @param self              The deployments object
   *
   * @param namePath          The name or namepath of the contract to deploy,
   *                          e.g. Counter or src/Counter.sol:Counter
   *
   * @param creationCode      The creation code of the contract to deploy
   *                          (without constructor arguments)
   *
   * @param constructorArgs   The abi-encoded constructor arguments
   *
   * @param overrideExisting  Whether to override an existing deployment
   *                          if one already exists.
   *
   * @return deployment       The address of the deployed or retrieved contract
   * @return didDeploy        Whether the contract was deployed - false if it
   *                          already existed and was retrieved
   */
  function getOrDeploy(
    Deployments memory self,
    string memory namePath,
    bytes memory creationCode,
    bytes memory constructorArgs,
    bool overrideExisting
  ) internal returns (address deployment, bool didDeploy) {
    ContractArtifact memory artifact = parseContractNamePath(namePath);
    if (overrideExisting || !self.has(artifact.name)) {
      deployment = broadcastCreate(self, creationCode, constructorArgs);
      didDeploy = true;

      artifact.deployment = deployment;
      artifact.constructorArgs = constructorArgs;

      self.set(artifact.name, deployment);
      self.pushArtifact(artifact);

      console.log(string.concat('Deployed ', namePath, ' to'), deployment);
    } else {
      deployment = self.get(artifact.name);
      console.log(string.concat('Found ', namePath, ' at'), deployment);
    }
  }

  function getDeployment(
    Deployments memory self,
    string memory namePath
  ) internal returns (address deployment) {
    ContractArtifact memory artifact = parseContractNamePath(namePath);
    return self.get(artifact.name);
  }

  function getOrDeploy(
    Deployments memory deployments,
    string memory namePath,
    bytes memory creationCode,
    bytes memory constructorArgs
  ) internal returns (address deployment, bool didDeploy) {
    return getOrDeploy(deployments, namePath, creationCode, constructorArgs, false);
  }

  function getOrDeploy(
    Deployments memory self,
    string memory namePath,
    bytes memory creationCode,
    bool overrideExisting
  ) internal returns (address deployment, bool didDeploy) {
    return getOrDeploy(self, namePath, creationCode, '', overrideExisting);
  }

  function deploy(
    Deployments memory deployments,
    string memory namePath,
    bytes memory creationCode,
    bytes memory constructorArgs
  ) internal returns (address deployment) {
    (deployment, ) = getOrDeploy(deployments, namePath, creationCode, constructorArgs, true);
  }

  // ========================================================================== //
  //                                  Artifacts                                 //
  // ========================================================================== //

  /**
   * @dev Creates an artifact directory for the deployed contract at
   *      `deployments/<network-name>/<contract-name>-<deployment-address>/`
   *      with both the the solc output file and standard input json.
   */
  function writeDeploymentArtifact(
    Deployments memory deployments,
    ContractArtifact memory artifact
  ) internal {
    string memory deploymentName = string.concat(
      artifact.name,
      '-',
      artifact.deployment.toHexString()
    );

    artifact.artifactDir = pathJoin(deployments.dir, deploymentName);
    mkdir(artifact.artifactDir);

    StandardInputJson.writeStandardJson(artifact);
    if (artifact.constructorArgs.length > 0) {
      forgeVm.writeFile(
        pathJoin(artifact.artifactDir, 'constructor-args'),
        artifact.constructorArgs.toHexString()
      );
    }
    string memory jsonPath = findForgeArtifact(artifact, deployments.forgeOutDir);
    forgeVm.copyFile(jsonPath, pathJoin(artifact.artifactDir, 'output.json'));

    console.log(string.concat('Wrote deployment artifact to ', artifact.artifactDir));
  }

  /**
   * @dev Writes the created deployments to disk.
   *
   *      1. Writes a mapping from contract name to most recently deployed address
   *      to `deployments/<network-name>/deployments.json`.
   *
   *      2. Writes the artifact for each newly deployed contract to its own subdirectory
   *      within the network deployments directory. Artifacts contain standard
   *      input json, compiler output and constructor args (if any).
   */
  function write(Deployments memory deployments) internal {
    deployments.deployments.write(deployments.filePath);
    console.log(string.concat('Wrote deployments to ', deployments.filePath));
    for (uint256 i = 0; i < deployments.artifacts.length; i++) {
      ContractArtifact memory artifact = deployments.artifacts[i];
      writeDeploymentArtifact(deployments, artifact);
    }
  }

  function pushArtifact(
    Deployments memory deployments,
    ContractArtifact memory artifact
  ) internal pure {
    ContractArtifact[] memory artifacts = deployments.artifacts;
    ContractArtifact[] memory newArtifacts = new ContractArtifact[](artifacts.length + 1);
    for (uint256 i = 0; i < artifacts.length; i++) {
      newArtifacts[i] = artifacts[i];
    }
    newArtifacts[artifacts.length] = artifact;
    deployments.artifacts = newArtifacts;
  }

  function pushArtifactFor(
    Deployments memory deployments,
    string memory namePath
  ) internal pure returns (ContractArtifact memory) {
    ContractArtifact memory artifact = parseContractNamePath(namePath);
    deployments.pushArtifact(artifact);
    return artifact;
  }

  // ========================================================================== //
  //                                  Utilities                                 //
  // ========================================================================== //

  function broadcast(Deployments memory deployments) internal {
    uint256 key = forgeVm.envOr(deployments.privateKeyVarName, uint256(0));
    if (key == 0) {
      forgeVm.broadcast();
    } else {
      forgeVm.broadcast(key);
    }
  }

  function broadcastCreate(
    Deployments memory deployments,
    bytes memory creationCode,
    bytes memory constructorArgs
  ) internal returns (address deployment) {
    bytes memory initCode = abi.encodePacked(creationCode, constructorArgs);
    deployments.broadcast();
    assembly {
      deployment := create(0, add(initCode, 0x20), mload(initCode))
    }
  }

  function broadcastDeployInitcode(
    Deployments memory deployments,
    bytes memory creationCode
  ) internal returns (address deployment) {
    deployments.broadcast();
    deployment = LibStoredInitCode.deployInitCode(creationCode);
  }

  function findForgeArtifact(
    ContractArtifact memory artifact,
    string memory forgeOutDir
  ) internal returns (string memory) {
    if (bytes(artifact.namePath).length != bytes(artifact.name).length) {
      string memory namePath = artifact.namePath.split(':')[0];
      string[] memory components = namePath.split('/');
      string memory fileName = components[components.length - 1];
      fileName = string.concat(fileName, '/', artifact.name, '.json');
      for (uint256 i = components.length - 1; i > 0; i--) {
        string memory prev = components[i - 1];
        fileName = pathJoin(prev, fileName);
        string memory searchPath = pathJoin(forgeOutDir, fileName);
        if (forgeVm.exists(searchPath)) {
          return searchPath;
        }
      }
    }
    string memory jsonPath = pathJoin(
      forgeOutDir,
      string.concat(artifact.name, '.sol/', artifact.name, '.json')
    );
    if (forgeVm.exists(jsonPath)) {
      return jsonPath;
    }
    revert(string.concat('Could not find forge artifact for ', artifact.name, ' in ', forgeOutDir));
  }

  function withPrivateKeyVarName(
    Deployments memory deployments,
    string memory privateKeyVarName
  ) internal pure returns (Deployments memory) {
    deployments.privateKeyVarName = privateKeyVarName;
    return deployments;
  }
}

function mkdir(string memory path) {
  if (!forgeVm.exists(path)) {
    forgeVm.createDir(path, true);
  }
}

function pathJoin(string memory a, string memory b) pure returns (string memory) {
  uint aLen;
  uint bLen;
  assembly {
    aLen := mload(a)
    bLen := mload(b)
  }
  if (a.endsWith('/')) {
    a = a.slice(0, aLen - 1);
  }
  if (b.startsWith('/')) {
    b = b.slice(1);
  }
  return join(a, b, '/');
}

function join(
  string memory a,
  string memory b,
  string memory separator
) pure returns (string memory) {
  if (bytes(a).length == 0) return b;
  if (bytes(b).length == 0) return a;
  return string.concat(a, separator, b);
}

function getNetworkName() view returns (string memory) {
  return block.chainid == 1 ? 'mainnet' : block.chainid == 11155111 ? 'sepolia' : '';
}

/**
 * @dev Gets the forge output directory for the current profile
 *      using FFI. When forge is run inside of a running forge
 *      script, it automatically populates the correct profile.
 */
function getForgeOutputDirectory() returns (string memory) {
  string[] memory args = new string[](4);
  args[0] = 'forge';
  args[1] = 'config';
  args[2] = '--basic';
  args[3] = '--json';
  return forgeVm.parseJsonString(string(forgeVm.ffi(args)), '.out');
}

function parseContractNamePath(string memory namePath) pure returns (ContractArtifact memory path) {
  path.namePath = namePath;
  // Examples
  // Counter => Counter
  // src/Counter.sol:Counter => Counter
  uint256 indexOfSlash = namePath.indexOf('/');
  if (indexOfSlash == LibString.NOT_FOUND) {
    path.name = namePath;
  } else {
    uint256 indexOfColon = namePath.indexOf(':');
    if (indexOfColon == LibString.NOT_FOUND) {
      revert('Invalid contract name path. Should be <contract-name> or <path>:<contract-name>');
    }
    path.name = namePath.slice(indexOfColon + 1);
  }
}

library StandardInputJson {
  function checkForBashFile() internal {
    if (!forgeVm.exists(bashFilePath)) {
      string
        memory bashFile = 'forge verify-contract --show-standard-json-input 0x0000000000000000000000000000000000000000 $1 > $2 && echo ok';
      forgeVm.writeFile(bashFilePath, bashFile);
      console.log(string.concat('Wrote bash file to ', bashFilePath));
    }
  }

  function writeStandardJson(ContractArtifact memory artifact) internal {
    checkForBashFile();
    string[] memory args = new string[](4);
    args[0] = 'bash';
    args[1] = bashFilePath;
    args[2] = artifact.namePath;
    args[3] = pathJoin(artifact.artifactDir, 'standard-input.json');
    bytes memory result = forgeVm.ffi(args);
    bytes32 resultBytes;
    assembly {
      resultBytes := mload(add(result, 32))
    }
    if (resultBytes != 'ok') {
      if (result.length > 0) {
        console.logBytes('Output from bash script:');
        console.logBytes(result);
      }
      revert('Failed to write standard input json');
    }
    console.logBytes(result);
  }
}

library JsonUtil {
  bytes32 internal constant JSON_ID_SLOT = bytes32(uint256(keccak256('deployments.json.id')) - 1);

  function create() internal returns (Json memory json) {
    bytes32 jsonIdSlot = JSON_ID_SLOT;
    assembly {
      // Increment counter
      let counter := sload(jsonIdSlot)
      sstore(jsonIdSlot, add(counter, 1))

      // Get unique id
      mstore(0, address())
      mstore(32, counter)
      let id := keccak256(0, 64)

      // Get id string
      let ptr := mload(0x40)
      mstore(ptr, 32)
      mstore(0x40, add(ptr, 64))

      mstore(add(ptr, 32), id)
      mstore(json, ptr)
    }
  }

  function create(string memory jsonString) internal returns (Json memory json) {
    json = create();
    json.serialized = forgeVm.serializeJson(json.id, jsonString);
  }

  function write(Json memory self, string memory filePath) internal {
    forgeVm.writeFile(filePath, self.serialized);
  }

  function set(Json memory self, string memory key, address value) internal {
    self.serialized = forgeVm.serializeAddress(self.id, key, value);
  }

  function set(Json memory self, string memory key, Json memory value) internal {
    self.serialized = forgeVm.serializeString(self.id, key, value.serialized);
  }

  function has(Json memory self, string memory key) internal view returns (bool) {
    return forgeVm.keyExists(self.serialized, string.concat('.', key));
  }

  function get(Json memory json, string memory key) internal pure returns (address) {
    return forgeVm.parseJsonAddress(json.serialized, string.concat('.', key));
  }

  function has(Deployments memory deployments, string memory name) internal view returns (bool) {
    return has(deployments.deployments, name);
  }

  function get(Deployments memory deployments, string memory name) internal pure returns (address) {
    return get(deployments.deployments, name);
  }

  function set(Deployments memory deployments, string memory name, address value) internal {
    deployments.deployments.set(name, value);
  }
}

function isFfiEnabled() returns (bool result) {
  string[] memory args = new string[](2);
  args[0] = 'echo';
  args[1] = 'ok';
  try forgeVm.ffi(args) returns (bytes memory result) {
    bytes32 resultBytes;
    assembly {
      resultBytes := mload(add(result, 32))
    }
    if (resultBytes != 'ok') {
      if (result.length > 0) {
        console.logBytes('Unexpected output from bash script:');
        console.logBytes(result);
      }
      revert('Failed to validate FFI access.');
    }
    return true;
  } catch {
    result = false;
  }
}

function checkFfiEnabled() {
  if (!isFfiEnabled()) {
    revert(
      'LibDeployment requires FFI to generate standard input json files. Please enable FFI in foundry.toml using `ffi=true`.'
    );
  }
}

function checkDirectoryExistsAndAccessible(string memory dir, bool writeAccess) {
  string memory requestString = string.concat(
    ' Please grant read',
    writeAccess ? '-write' : '',
    ' permission for `',
    dir,
    '` in foundry.toml.'
  );
  string memory readErrorMessage = string.concat(
    'LibDeployment requires access to the `',
    dir,
    '` directory.',
    requestString
  );
  string memory writeErrorMessage = string.concat(
    'LibDeployment requires access to the `',
    dir,
    '` directory but',
    ' the current configuration only provides read access.',requestString
  );
  bool dirExists;
  try forgeVm.exists(dir) returns (bool exists) {
    dirExists = exists;
  } catch {
    revert(readErrorMessage);
  }
  if (dirExists && !writeAccess) {
    return;
  }
  if (!dirExists) {
    try forgeVm.createDir(dir, true) {
      console.log(string.concat('Created directory: ', dir));
    } catch {
      revert(writeErrorMessage);
    }
  }
  try forgeVm.writeFile(pathJoin(dir, 'test'), '') {
    forgeVm.removeFile(pathJoin(dir, 'test'));
  } catch {
    revert(writeErrorMessage);
  }
}
