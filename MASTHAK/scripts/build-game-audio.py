"""Original, deterministic procedural sound assets; no third-party samples."""
import math, random, wave, struct, pathlib
OUT=pathlib.Path('godot/audio');OUT.mkdir(exist_ok=True)
RATE=22050
def save(name, samples):
    peak=max(1.0,max(abs(x) for x in samples))
    with wave.open(str(OUT/(name+'.wav')),'wb') as stream:
        stream.setnchannels(1);stream.setsampwidth(2);stream.setframerate(RATE)
        stream.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,x/peak))*27000)) for x in samples))
def tone(data,start,duration,freq,volume=.15,decay=6,slide=0):
    for i in range(int(duration*RATE)):
        index=int(start*RATE)+i
        if index>=len(data):break
        t=i/RATE;envelope=min(1,t*200)*math.exp(-t/duration*decay)
        phase=math.tau*(freq*t+slide*t*t/2)
        data[index]+=(math.sin(phase)+.2*math.sin(phase*2))*envelope*volume
def noise(data,start,duration,volume,seed):
    rng=random.Random(seed);previous=0
    for i in range(int(duration*RATE)):
        index=int(start*RATE)+i
        if index>=len(data):break
        x=rng.uniform(-1,1);high=x-previous;previous=x
        data[index]+=high*volume*math.exp(-i/(duration*RATE)*7)
duration=16;music=[0.0]*int(duration*RATE)
for step in range(128):
    start=step*.125;root=[110,130.8128,98,146.8324][step//32]
    if step%4==0:tone(music,start,.2,100,.33,8,-320)
    if step%8==4:noise(music,start,.13,.1,step)
    noise(music,start,.035,.017 if step%2 else .012,step+123)
    if step%2==0:tone(music,start,.22,root,.12)
    melody=[1,1.5,2,2.5,2,1.5,1.25,1.5][step%8]
    tone(music,start,.18,root*2*melody,.04)
    if step%16==0:
        for ratio in [1,1.25,1.5]:tone(music,start,1.6,root*ratio,.025,3)
save('arcade-loop',music)
print('Original arcade soundtrack generated.')
