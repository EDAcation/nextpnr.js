import fs from 'fs';
import path from 'path';

/* eslint-disable @typescript-eslint/no-var-requires */
const packageJson = require('../package.json');

const InitNextpnrEcp5: EmscriptenModuleFactory<NextpnrModule> = require('./nextpnr-ecp5.js');
const InitNextpnrIce40: EmscriptenModuleFactory<NextpnrModule> = require('./nextpnr-ice40.js');
/* eslint-enable @typescript-eslint/no-var-requires */

export type EmscriptenFS = typeof FS;

export interface NextpnrModule extends EmscriptenModule {
    FS: EmscriptenFS;
}

export type NextpnrArchitecture = 'ecp5' | 'ice40';

const initByArchitecture: Record<NextpnrArchitecture, EmscriptenModuleFactory<NextpnrModule>> = {
    'ecp5': InitNextpnrEcp5,
    'ice40': InitNextpnrIce40
}

export class Nextpnr {

    static getVersion() {
        return packageJson.version;
    }

    static async initialize({architecture, wasmBinary, ...args}: Parameters<EmscriptenModuleFactory>[0] & {architecture: NextpnrArchitecture} = {
        architecture: 'ice40'
    }) {
        const InitNextpnr = initByArchitecture[architecture];

        return new Nextpnr(await InitNextpnr({
            wasmBinary: wasmBinary ? wasmBinary : fs.readFileSync(path.join(__dirname, `nextpnr-${architecture}.wasm`)),
            ...args
        }));
    }

    private module: NextpnrModule;

    constructor(module: NextpnrModule) {
        this.module = module;
    }

    getModule() {
        return this.module;
    }

    getFS() {
        return this.module.FS;
    }
}
