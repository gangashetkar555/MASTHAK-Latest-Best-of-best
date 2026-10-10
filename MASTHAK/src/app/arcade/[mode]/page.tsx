import {notFound} from 'next/navigation';
import {modes} from '@/data/content';
import Game from '@/components/Game';
export function generateStaticParams(){return modes.map(m=>({mode:m.id}))}
export default async function GamePage({params}:{params:Promise<{mode:string}>}){const {mode}=await params;const m=modes.find(m=>m.id===mode);if(!m)notFound();return <div className="page page-enter"><div className="page-title"><div className="eyebrow">THE SORTING TRIAL / {m.tag}</div><h1>{m.name.split(' ')[0]}{' '}<em>{m.name.split(' ').slice(1).join(' ')}.</em></h1><p>{m.description}</p></div><Game mode={mode}/></div>}
