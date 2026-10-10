'use client';
import {useState} from 'react';
export default function LocalData(){const[done,setDone]=useState(false);return <div className="data-control"><button className="button secondary" onClick={()=>{try{for(const key of Object.keys(localStorage))if(key.startsWith('masthak-'))localStorage.removeItem(key);setDone(true)}catch{setDone(false)}}}>Delete my local game data</button><p role="status">{done?'Your MASTHAK scores and preferences have been deleted from this browser.':'This deletes only MASTHAK data saved on this browser. No account or email is needed.'}</p></div>}
