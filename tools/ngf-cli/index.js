const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
const command = args[0];
const moduleName = args[1];

if (command !== 'generate' || !moduleName) {
  console.log('Usage: node tools/ngf-cli/index.js generate <ModuleName>');
  process.exit(1);
}

const basePath = path.join(__dirname, '../../ngf_framework/src/main/ets', moduleName);
const contractsPath = path.join(basePath, 'contracts');
const facadesPath = path.join(basePath, 'facades');

// Create directories
fs.mkdirSync(contractsPath, { recursive: true });
fs.mkdirSync(facadesPath, { recursive: true });

// 1. Contract
const capitalized = moduleName.charAt(0).toUpperCase() + moduleName.slice(1);
const contractCode = `export interface I${capitalized}Manager {
  // TODO: Define your interface here
}
`;
fs.writeFileSync(path.join(contractsPath, `I${capitalized}Manager.ets`), contractCode);

// 2. Facade
const facadeCode = `import { NGFIntegrationFacadeBase } from '../../core/facades/NGFIntegrationFacadeBase';
import { I${capitalized}Manager } from '../contracts/I${capitalized}Manager';

export class ${capitalized}Facade extends NGFIntegrationFacadeBase implements I${capitalized}Manager {
  getServiceRegistrations(): void {
    // TODO: Register your services to DI container
  }

  bootstrap(): void {
    // TODO: Initialize your module
  }

  syncAppStorage(): void {
    // TODO: Sync state to AppStorage
  }
}

export const ngf${capitalized}Facade = new ${capitalized}Facade();
`;
fs.writeFileSync(path.join(facadesPath, `${capitalized}Facade.ets`), facadeCode);

// 3. index.ets
const indexCode = `export * from './contracts/I${capitalized}Manager';
export * from './facades/${capitalized}Facade';
`;
fs.writeFileSync(path.join(basePath, 'index.ets'), indexCode);

console.log(`Successfully generated module ${moduleName} at ${basePath}`);
