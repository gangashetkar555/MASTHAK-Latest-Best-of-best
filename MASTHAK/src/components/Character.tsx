'use client';
import {useId} from 'react';
export default function Character({id,className='',pose=0,sheet=false}:{id:string,className?:string,pose?:number,sheet?:boolean}){
 const clip=useId();
 if(id==='battery'||id==='wrapper')return <span className={`item-symbol ${className}`} role="img" aria-label={id==='battery'?'Used battery':'Mixed material wrapper'}>{id==='battery'?'🔋':'🍬'}</span>;
 if(sheet){const rows=id==='judge'?[5,5,5,6]:id==='bottle'?[5,5,6,5]:id==='maya'?[5,5,5,5]:[6,6,6,6];let row=0,col=pose;while(col>=rows[row]&&row<3){col-=rows[row];row++}const dimensions:Record<string,[number,number]>={banana:[409,610],bottle:[338,737],judge:[457,546],leaf:[404,617],maya:[345,722]};const [width,height]=dimensions[id]||[400,600],top=['leaf','maya'].includes(id)?0:height*.035,cw=width/rows[row],ch=(height-top)/4;return <svg className={`character sheet-character ${className}`} role="img" aria-label={`${id==='judge'?'Judge Cardboard':id}, character expression`} viewBox={`${col*cw} ${top+row*ch} ${cw} ${ch}`}><defs><clipPath id={clip}><rect x={col*cw} y={top+row*ch} width={cw} height={ch}/></clipPath></defs><image clipPath={`url(#${clip})`} href={`/assets/sheets/${id}.png`} width={width} height={height}/></svg>}

 return <img className={`character ${className}`} src={`/assets/characters/${id}.png`} alt={id==='judge'?'Judge Cardboard':id==='bottle'?'Plastic Bottle':id} draggable={false}/>;
}
