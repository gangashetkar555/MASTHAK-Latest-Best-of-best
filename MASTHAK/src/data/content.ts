export const characters = [
 {id:'maya',name:'Maya',role:'The curious human',line:'One ordinary day. One extraordinary wake-up call.',color:'#eee4f3'},
 {id:'judge',name:'Judge Cardboard',role:'The voice of reason',line:'Order in the court! Every material deserves a fair hearing.',color:'#eadac4'},
 {id:'banana',name:'Banana Peel',role:'The compost optimist',line:'My next chapter? Helping something new grow.',color:'#f4eac8'},
 {id:'bottle',name:'Plastic Bottle',role:'The second-chance seeker',line:'Empty doesn’t mean useless. Give me another life.',color:'#dfedf0'},
 {id:'leaf',name:'Leaf',role:'The quiet earthkeeper',line:'Back to the soil. Back to the beginning.',color:'#e4ead8'},
];
export const waste=[
 {id:'banana',name:'Banana peel',category:0,years:0.1,label:'Weeks to months',fact:'Composting returns nutrients to the soil. Actual breakdown depends on moisture, temperature, and oxygen.'},
 {id:'leaf',name:'Dry leaves',category:0,years:1,label:'Months to years',fact:'Leaves make useful compost and mulch. Their thickness and the conditions change how quickly they break down.'},
 {id:'judge',name:'Clean cardboard',category:1,years:0.2,label:'Weeks to months',fact:'Keep cardboard clean and dry for recycling. Food-soiled cardboard may be compostable where accepted.'},
 {id:'bottle',name:'Plastic bottle',category:1,years:450,label:'Hundreds of years',fact:'Plastic fragments into smaller pieces rather than becoming harmless soil. Recycling acceptance depends on local facilities.'},
 {id:'battery',name:'Used battery',category:3,years:0,label:'No safe decay timeline',fact:'Batteries need a designated collection point. Keep them out of compost and ordinary recycling.'},
 {id:'wrapper',name:'Mixed wrapper',category:2,years:0,label:'Material dependent',fact:'Multilayer wrappers are difficult to recycle. Use your local residual stream unless a dedicated collection scheme accepts them.'}
];
export const bins=['Compost','Recycling','Residual','Special collection'];
export const modes=[{id:'conveyor',name:'Conveyor Sort',tag:'QUICK THINKING',description:'A moving belt. A ticking clock. Give every item the right destination.',icon:'↔',color:'#e4ebdb'}, {id:'shooter',name:'Garbage Court',tag:'AIM WITH PURPOSE',description:'Five 3D stages. Five sorting tools. Explore the maze and face the judge.',icon:'◎',color:'#eee0cd'}, {id:'tunnel',name:'Eco Velocity',tag:'TAKE FLIGHT',description:'Surf a circular 3D tunnel. Recover energy, clear debris, and find the next gap.',icon:'△',color:'#dce9ec'}, {id:'defense',name:'Garbage Defense',tag:'THINK STRATEGICALLY',description:'Protect Maya’s home with the right sorting stations in five lanes.',icon:'▥',color:'#e8dfed'}];
