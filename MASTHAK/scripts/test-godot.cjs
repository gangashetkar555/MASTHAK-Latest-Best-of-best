const {spawnSync}=require('node:child_process');
const exe=process.env.GODOT_BIN||'godot';
const imported=spawnSync(exe,['--headless','--editor','--import','--quit','--path','godot'],{encoding:'utf8',timeout:90000});
if(imported.error||imported.status!==0||/SCRIPT ERROR|^ERROR:/m.test((imported.stdout||'')+(imported.stderr||''))){
 console.error(imported.error?.message||(imported.stdout||'')+(imported.stderr||''));
 console.error('Install Godot 4.7.2 and set GODOT_BIN to its executable, or put godot on PATH. See readme.txt.');
 process.exit(1);
}
for(const [args,marker] of [[['--script','res://tests/check.gd'],'MASTHAK_RULES_OK'],[['--','--smoke'],'MASTHAK_SMOKE_OK'],[['--','--input-test'],'MASTHAK_INPUT_OK']]) {
 const r=spawnSync(exe,['--headless','--path','godot',...args],{encoding:'utf8',timeout:45000});
 const out=(r.stdout||'')+(r.stderr||''); process.stdout.write(out);
 if(r.error||r.status!==0||!out.includes(marker)||/SCRIPT ERROR|^ERROR:/m.test(out))process.exit(1);
}
