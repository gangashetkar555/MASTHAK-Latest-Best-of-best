

'use client';
import {useEffect,useRef,useState} from 'react';
import Link from 'next/link';
import {ArrowLeft,ArrowRight,ArrowUpRight,BookOpen,Volume2,X,Leaf,Check,RotateCcw} from 'lucide-react';
import {chapters} from '@/data/comic';
import {bins} from '@/data/content';

const scenes=['THE ORDINARY / A MORNING LIKE ANY OTHER','THE HEARING / EVERY MATERIAL HAS A VOICE','THE TRIAL / YOUR CHOICE MATTERS','THE REALITY / THERE IS NO AWAY','THE VERDICT / DIFFERENT FUTURES'];
const covers=[{file:'/assets/comic/cover.png',alt:'Maya and the Garbage Court cast'},{file:'/assets/characters/judge.png',alt:'Judge Cardboard calls the court to order'},{file:'/assets/characters/banana.png',alt:'Banana Peel awaits the sorting trial'},{file:'/assets/characters/maya.png',alt:'Maya considers the consequences'},{file:'/assets/characters/leaf.png',alt:'Leaf stands for a new beginning'}];
const trial:Record<number,{answer:number,name:string,explanation:string}>={3:{answer:0,name:'Banana peel',explanation:'Organic material belongs in a suitable compost stream. It can return nutrients to the soil.'},4:{answer:1,name:'Plastic bottle',explanation:'Keep accepted bottles empty and separate for recycling. Check what your local service accepts.'},5:{answer:3,name:'Used battery',explanation:'A battery needs a designated collection point. Keep it out of compost and ordinary recycling.'}};
type Result={correct:boolean,choice:number};

export default function Comic(){
 const [book,setBook]=useState<number|null>(null),[panel,setPanel]=useState(0),[whole,setWhole]=useState(false),[narration,setNarration]=useState(false),[ended,setEnded]=useState(false),[answers,setAnswers]=useState<Record<number,Result>>({}),[promise,setPromise]=useState<string|null>(null);
 const chapterDialog=useRef<HTMLDialogElement>(null),audio=useRef<HTMLAudioElement>(null);
 const current=chapters[book??0],question=book===2?trial[panel]:undefined,result=answers[panel];
 const restored=Object.values(answers).filter(a=>a.correct).length;
 const begin=(index:number)=>{setBook(index);setPanel(0);setWhole(false);setNarration(false);setEnded(false);chapterDialog.current?.close();window.scrollTo({top:0,behavior:'instant'})};
 const shelf=()=>{audio.current?.pause();setBook(null);setEnded(false);setNarration(false);setWhole(false)};
 const next=()=>{if(book===null)return;setWhole(false);if(panel<current.lines.length-1)setPanel(panel+1);else if(book<4)begin(book+1);else setEnded(true)};
 const previous=()=>{if(book===null)return;setWhole(false);if(panel>0)setPanel(panel-1);else if(book>0){setBook(book-1);setPanel(chapters[book-1].lines.length-1);setNarration(false)}};
 const choose=(choice:number)=>{if(!question||result?.correct)return;setAnswers(old=>({...old,[panel]:{choice,correct:question.answer===choice}}))};
 useEffect(()=>{const initial=Number(new URLSearchParams(location.search).get('book'));if(initial>=1&&initial<=5)begin(initial-1)},[]);
 useEffect(()=>{
  if(book===null||ended)return;
  const keys=(event:KeyboardEvent)=>{if(chapterDialog.current?.open)return;if(event.key==='Escape'){shelf();return}const target=event.target as HTMLElement;if(target.closest('input,select,textarea,audio,summary')||(event.key===' '&&target.closest('button,a')))return;
   if(event.key===' '||event.key==='ArrowRight'){event.preventDefault();next()}
   if(event.key==='ArrowLeft'){event.preventDefault();previous()}
   if(question&&/^[1-4]$/.test(event.key))choose(Number(event.key)-1);
  };window.addEventListener('keydown',keys);return()=>window.removeEventListener('keydown',keys);
 },[book,panel,ended,question,result]);
 useEffect(()=>{if(book===null||ended)return;const preload=new Image();if(panel+1<current.lines.length)preload.src=`/assets/story/book-${book+1}-panel-${panel+2}.webp`},[book,panel,ended]);

 if(book===null)return <div className="story-shelf">
  <header className="story-shelf-header"><Link href="/" className="story-brand"><Leaf size={22}/> MASTHAK</Link><Link href="/">Return to the courtyard <ArrowUpRight size={16}/></Link></header>
  <div className="story-shelf-intro"><span className="scene-eyebrow">FIVE CHAPTERS / ONE EXTRAORDINARY DAY</span><h1>The discarded<br/>have a <em>story.</em></h1><p>Enter the Garbage Court. Hear the evidence.<br/>Choose a better ending.</p><button className="court-enter" onClick={()=>begin(0)}>Begin story <ArrowRight size={19}/></button></div>
  <div className="story-books">{chapters.map((ch,i)=><button className="story-book" key={ch.title} onClick={()=>begin(i)}><div className={`story-book-cover ${i>0?'character-cover':''}`}><img src={covers[i].file} alt={covers[i].alt} loading={i===0?'eager':'lazy'} width="260" height="390"/><div><small>BOOK 0{i+1}</small><h2>{ch.title}</h2><span>THE GARBAGE COURT</span></div></div><span>0{i+1} / {ch.lines.length} PANELS <ArrowUpRight size={17}/></span></button>)}</div>
  <div className="story-shelf-note"><BookOpen size={18}/><p>Read at your own pace. Click Next or press Space.<br/>Original comic artwork · Captions always available · Optional book narration</p></div><Link className="story-text-link" href="/arcade">Already know the story? Play your part <ArrowUpRight size={16}/></Link>
 </div>;

 if(ended)return <div className="story-ending"><Link href="/" className="story-brand"><Leaf size={22}/> MASTHAK</Link><span className="scene-eyebrow">THE VERDICT / YOUR NEXT CHAPTER</span><h1>Different materials.<br/><em>Different futures.</em></h1><p>You heard their side. Now make one small choice of your own.</p>{restored>0&&<span className="story-result"><Check size={17}/>{restored} of 3 material futures restored in the trial</span>}<div className="story-promises">{['Keep organics separate','Check local recycling rules','Take batteries to a collection point'].map(p=><button aria-pressed={promise===p} key={p} onClick={()=>setPromise(p)}>{promise===p?<Check size={18}/>:<Leaf size={18}/>} {p}</button>)}</div><p aria-live="polite">{promise?`Your next step: ${promise.toLowerCase()}.`:'Choose a next step, or keep exploring below.'}</p><div className="story-ending-actions"><Link href="/arcade" className="court-enter">Play your part <ArrowUpRight size={18}/></Link><Link href="/decay">See what remains <ArrowRight size={16}/></Link><button onClick={()=>{setAnswers({});setPromise(null);begin(0)}}><RotateCcw size={16}/> Read again</button></div><button className="story-text-link" onClick={shelf}>Return to the bookshelf</button></div>;

 return <div className="story-theatre">
  <header className="story-reader-header"><button onClick={shelf} aria-label="Return to the bookshelf"><ArrowLeft size={19}/><span>Bookshelf</span></button><div><small>BOOK 0{book+1} / 05</small><h1>{current.title}</h1></div><div className="story-reader-tools"><button onClick={()=>chapterDialog.current?.showModal()} aria-label="Choose a chapter"><BookOpen size={18}/><span>Chapters</span></button><button onClick={()=>setNarration(!narration)} aria-label="Narration" aria-expanded={narration}><Volume2 size={18}/><span>Narration</span></button></div></header>
  <div className="story-progress" aria-label={`Chapter progress: panel ${panel+1} of ${current.lines.length}`}><span style={{width:`${(panel+1)/current.lines.length*100}%`}}/></div>
  <section className="story-scene" aria-label="Story panel"><div className="story-scene-top"><span className="scene-eyebrow">{scenes[book]}</span><button onClick={()=>setWhole(!whole)} aria-pressed={whole}>{whole?'Back to the panel':'View original page'} <ArrowUpRight size={14}/></button></div>
   <div className={`story-scene-body ${question&&!whole?'has-choice':''}`}>
    <div className="story-frame" key={`${book}-${panel}-${whole}`}><span className="story-panel-tag">PANEL {String(panel+1).padStart(2,'0')}</span><img className="story-panel-image" src={whole?`/assets/comic/${current.file}`:`/assets/story/book-${book+1}-panel-${panel+1}.webp`} alt={whole?`Original comic page for ${current.title}`:`Panel ${panel+1}: ${current.lines[panel]}`} width="1000" height="800" fetchPriority="high"/></div>
    {question&&!whole&&<fieldset className="story-choice"><legend>YOUR TURN / {question.name}</legend><h2>Where does it go?</h2><p>The court is listening.<br/>Choose a destination.</p><div>{bins.map((bin,i)=><button key={bin} onClick={()=>choose(i)} aria-pressed={result?.choice===i} className={result?.correct&&result.choice===i?'correct':''}><span>{i+1}</span>{bin}{result?.correct&&result.choice===i&&<Check size={17}/>}</button>)}</div><p className={`story-choice-feedback ${result?.correct?'correct':''}`} role="status">{result?(result.correct?question.explanation:`Not this stream. Try another destination for the ${question.name.toLowerCase()}.`):'Keys 1–4 also choose a destination.'}</p></fieldset>}
   </div>
   <div className="story-caption"><span>{current.speakers[panel]==='judge'?'JUDGE CARDBOARD':current.speakers[panel].toUpperCase()}</span><p aria-live="polite">{current.lines[panel]}</p><button onClick={next} aria-label={panel===current.lines.length-1?(book===4?'See the verdict':'Next chapter'):'Next panel'}>{panel===current.lines.length-1?(book===4?'The verdict':'Next chapter'):'Next'} <ArrowRight size={19}/></button></div>
  </section>
  <div className="story-reader-bottom"><button onClick={previous} disabled={book===0&&panel===0}><ArrowLeft size={16}/> Previous</button><nav aria-label="Choose a panel">{current.lines.map((_,i)=><button key={i} aria-label={`Go to panel ${i+1}`} aria-current={panel===i?'step':undefined} onClick={()=>{setPanel(i);setWhole(false)}}><span/></button>)}</nav><small>{panel+1} / {current.lines.length}<span> · SPACE TO CONTINUE</span></small></div>
  {narration&&<section className="story-narration"><div><strong>Book {book+1} narration · elevenlabs.io</strong><small>Full chapter audio. Panel navigation stays in your hands.</small></div><audio key={book} ref={audio} controls preload="none" src={`/assets/audio/book-${book+1}.mp3`} aria-label={`Book ${book+1} narration`}/><button onClick={()=>setNarration(false)} aria-label="Close narration controls"><X size={18}/></button><details><summary>Narration transcript</summary><p>{current.lines.join(' ')}</p></details></section>}
  <dialog ref={chapterDialog} className="story-chapter-dialog" aria-labelledby="chapter-picker-title"><div><h2 id="chapter-picker-title">Choose a chapter</h2><button onClick={()=>chapterDialog.current?.close()} aria-label="Close chapter picker"><X size={22}/></button></div>{chapters.map((ch,i)=><button key={ch.title} onClick={()=>begin(i)} aria-current={book===i?'true':undefined}><span>0{i+1}</span>{ch.title}<ArrowUpRight size={18}/></button>)}<small>Pick any chapter. Your trial choices stay until you restart the story.</small></dialog>
 </div>;
}


