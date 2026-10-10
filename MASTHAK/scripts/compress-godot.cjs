const fs=require('node:fs'),zlib=require('node:zlib');
for(const name of ['index.wasm','index.pck','index.js']) {
 const path=`public/games/masthak/${name}`,raw=fs.readFileSync(path);
 const compressed=zlib.brotliCompressSync(raw,{params:{[zlib.constants.BROTLI_PARAM_QUALITY]:9}});
 fs.writeFileSync(`${path}.br`,compressed);
 console.log(`${name}: ${(raw.length/1048576).toFixed(2)} MB -> ${(compressed.length/1048576).toFixed(2)} MB`);
}
