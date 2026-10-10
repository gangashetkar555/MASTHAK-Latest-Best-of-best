import type { NextConfig } from 'next';
const config: NextConfig = {
 turbopack: {root: process.cwd()},
 devIndicators: false,
 async rewrites(){return {beforeFiles:['wasm','pck','js'].map(ext=>({source:`/games/masthak/index.${ext}`,has:[{type:'header' as const,key:'accept-encoding',value:'.*br.*'}],destination:`/games/masthak/index.${ext}.br`}))}},
 async headers(){return ['wasm','pck','js'].flatMap(ext=>[false,true].map(direct=>({source:`/games/masthak/index.${ext}${direct?'.br':''}`,...(!direct?{has:[{type:'header' as const,key:'accept-encoding',value:'.*br.*'}]}:{}),headers:[{key:'Content-Encoding',value:'br'},{key:'Content-Type',value:ext==='wasm'?'application/wasm':ext==='js'?'application/javascript':'application/octet-stream'},{key:'Vary',value:'Accept-Encoding'}]})))},
};
export default config;
