
import dotenv from 'dotenv';
import { join } from 'path';
import fs from 'fs';

const envFile = join(__dirname, "..", ".env");
const config = dotenv.config({
  path: envFile
}).parsed;

if (!config) {
  console.error(`env file: ${envFile} open fail`);
  process.exit(1);
}

const apiHost = process.env.API_HOST
const abiDir = process.env.ABI_DIR
const abiFiles = process.env.ABI_FILE
const contracts = process.env.CONTRACTS

if (!apiHost || !abiDir || !abiFiles || !contracts) {
  console.error('Configuration file parameter error');
  process.exit(1);
}


const contractList = contracts.split(",")
var sceneMap = new Map();
contractList.forEach((row:any) => {
  sceneMap.set(row, row.toUpperCase());
});

// Check whether the API service is healthy
const checkHealthy = async () => {
  console.log("check api service......")
  const rs = await reqGet("/healthy");
  if (rs === false) {
    console.error("API service exception")
    return false;
  }
  return true;
}

const getArcGovernance = async () => {
  console.log("get arc governance......")
  const rs:any = await reqGet("/factory/sceneAddr?scene=ARCGOVERNANCE");
  if (rs === false) {
    return false;
  }

  const res = JSON.parse(rs);
  return res.payload;
}

// sync contract
const syncContracts = async () => {
  console.log("sync contracts......")
  let files = abiFiles.split(',')

  if (files.length == 0) {
    console.error('undefined abi file');
    return false;
  }

  for (let i = 0; i < files.length; i++) {

    let abiFileDir = files[i];
    let abiFileArr = abiFileDir.split('/');
    let name  = abiFileArr[abiFileArr.length - 1];

    let file = join(__dirname, "..", abiDir, abiFileDir + ".sol", name + ".json");

    if (!checkFile(file)) {
      return false;
    }

    let str = fs.readFileSync(file, 'utf8').toString();
    let content = JSON.parse(str);
    if (!content.abi) {
      console.error('undefined abi');
      return false;
    }

    if (!content.bytecode) {
      console.error('undefined bytecode');
      return false;
    }

    let data = { key: name, abi: JSON.stringify(content.abi), bytecode: content.bytecode }
    let rs = await reqPost("/contracts/set", data);
    if (!rs) {
      console.error(name + ":", "sync fail")
      return false;
    }

    console.log(name + ":", "sync success")
  }

  return true;
}

// update contract address
const postAddr = async (contractKey:string, addr:string) => {
  console.log("update contract address......")
  if (!contractKey) {
    console.error("undefined contract key");
    return false;
  }

  const secneVal = sceneMap.get(contractKey)

  if (!secneVal) {
    console.error("undefined scene val");
    return false;
  }

  if (!addr) {
    console.error("undefined address");
    return false;
  }

  const data = { scene: secneVal, addr: addr }
  let rs = await reqPost("/factory/addr", data);
  if (!rs) {
    console.error(secneVal + ":", "failed to update address")
    return false;
  }

  console.log(secneVal + ":", "address updated successfully")
  return true;
}

// get request
const reqGet = async (uri:string) => {
  const request = require('request')

  return await new Promise((resolve, reject) => {
    request.get({url: apiHost + uri,}, function (error:any, response:any, body:any) {
      if (!error && response.statusCode == 200) {
        return resolve(body);
      }
      return reject(false);
    })
  });
}


// post request
const reqPost = async (uri:string, data:any) => {
  const request = require('request')

  return await new Promise((resolve, reject) => {
    request.post({
      url: apiHost + uri,
      form: data
    }, function (error:any, response:any) {
      if (!error && response.statusCode == 200) {
        return resolve(true);
      }
      return reject(false);
    })
  });
}

// Check whether the file exists and has access rights
function checkFile(fileName:any) {
  fs.access(fileName, fs.constants.F_OK, (err) => {
    if (err) {
      console.error(`${fileName} does not exist`);
      return false;
    }
  });

  fs.access(fileName, fs.constants.R_OK, (err) => {
    if (err) {
      console.error(`No permission to read ${fileName}`);
      return false;
    }
  });

  return true;
}

// module.exports = {

// }

export{
  syncContracts,
  checkHealthy,
  postAddr,
  getArcGovernance,
  contractList,
}