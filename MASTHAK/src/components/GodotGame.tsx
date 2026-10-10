'use client';
import {useEffect,useRef,useState} from 'react';
import Link from 'next/link';
import {Maximize2,Play,RotateCcw} from 'lucide-react';

export default function GodotGame({mode,inline=false,onStart}:{mode:string,inline?:boolean,onStart?:()=>void}) {
 const [started,setStarted]=useState(false),[ready,setReady]=useState(false);
 const frame=useRef<HTMLIFrameElement>(null),container=useRef<HTMLDivElement>(null);
 useEffect(()=>{const listener=(event:MessageEvent)=>{if(event.origin===location.origin&&event.source===frame.current?.contentWindow&&event.data?.type==='masthak-ready')setReady(true)};window.addEventListener('message',listener);return()=>window.removeEventListener('message',listener)},[]);
 return <div className="godot-arcade"><div className="game-toolbar">{inline?<span>MASTHAK / {mode.toUpperCase()}</span>:<Link href="/arcade">← All missions</Link>}<div className="actions"><button className="button secondary" onClick={()=>{setStarted(false);setReady(false)}} disabled={!started}><RotateCcw size={16}/> Close game</button><button className="button secondary" onClick={()=>void container.current?.requestFullscreen()}><Maximize2 size={16}/> Fullscreen</button></div></div><div ref={container} style={{position:'relative',aspectRatio:'16 / 9',background:'#101720',borderRadius:8,overflow:'hidden',width:'100%'}}>{started?<><iframe ref={frame} src={`/games/masthak/index.html?mode=${encodeURIComponent(mode)}&v=6`} title={`MASTHAK ${mode} arcade`} allow="fullscreen; autoplay" style={{width:'100%',height:'100%',border:0,display:'block'}}/>{!ready&&<div className="game-overlay" style={{pointerEvents:'none'}}><h2>Loading…</h2><p>Preparing the shared arcade engine.</p></div>}</>:<div className="game-overlay"><div className="eyebrow">MASTHAK ARCADE</div><h2>Ready to play?</h2><button className="button primary" onClick={()=>{onStart?.();setStarted(true)}}><Play size={18}/> Open game</button></div>}</div><p className="game-help">Esc / P pauses. Sound, volume and difficulty are in the game settings. 3D missions use a keyboard and mouse.</p></div>
}


