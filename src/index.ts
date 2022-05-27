import fs from 'fs';
import path from 'path';

/* eslint-disable @typescript-eslint/no-var-requires */
const packageJson = require('../package.json');

const InitNextpnr: EmscriptenModuleFactory<NextpnrModule> = require('./nextpnr-ice40.js');
/* eslint-enable @typescript-eslint/no-var-requires */

export type EmscriptenFS = typeof FS;

export interface NextpnrModule extends EmscriptenModule {
    FS: EmscriptenFS;
}

export class Nextpnr {

    static getVersion() {
        return packageJson.version;
    }

    static async initialize({wasmBinary, ...args}: Parameters<EmscriptenModuleFactory>[0] = {}) {
        return new Nextpnr(await InitNextpnr({
            wasmBinary: wasmBinary ? wasmBinary : fs.readFileSync(path.join(__dirname, 'nextpnr-ice40.wasm')),
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
