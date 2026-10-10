"""Blender-generated low-poly assets, editable .blend source and compact GLBs."""
import bpy, math, os, struct, zlib
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'godot', 'assets')
SOURCE = os.path.join(ROOT, 'godot', 'blender')
os.makedirs(OUT, exist_ok=True); os.makedirs(SOURCE, exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
colors = {'moss':(.045,.16,.025,1),'leaf':(.10,.43,.035,1),'gold':(.98,.53,.008,1),'pale':(.99,.87,.37,1),'blue':(.012,.40,.72,1),'cap':(.018,.14,.30,1),'card':(.49,.23,.075,1),'paper':(.94,.87,.7,1),'ink':(.02,.025,.032,1),'coral':(.73,.18,.07,1),'metal':(.24,.31,.35,1),'purple':(.43,.12,.56,1)}
mats={}
for name,color in colors.items():
    mat=bpy.data.materials.new(name);mat.diffuse_color=color;mat.use_nodes=True
    bsdf=mat.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Base Color'].default_value=color;bsdf.inputs['Roughness'].default_value=.82
    mats[name]=mat

parts=[]
def finish(obj,material):
    obj.data.materials.append(mats[material]);parts.append(obj);return obj
def cube(loc,scale,mat,bevel=.04):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        modifier=o.modifiers.new('Small rounded edges','BEVEL');modifier.width=bevel;modifier.segments=1
        bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=modifier.name)
    return finish(o,mat)
def sphere(loc,scale,mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,location=loc);o=bpy.context.object;o.scale=scale;return finish(o,mat)
def cylinder(loc,radius,depth,mat,vertices=12):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=loc);return finish(bpy.context.object,mat)
def mesh(name,vertices,faces,mat):
    data=bpy.data.meshes.new(name);data.from_pydata(vertices,[],faces);data.update();o=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(o);return finish(o,mat)
def eyes(height,width=.16,front=-.3):
    for x in [-width,width]:
        sphere((x,front,height),(.12,.06,.15),'paper');sphere((x+.025,front-.055,height+.01),(.048,.022,.08),'ink')
    smile=cube((0,front-.025,height-.22),(.18,.025,.025),'ink',0)
def export(name):
    if name in ['banana','leaf','bottle','battery','wrapper']:
        for side in [-1,1]:
            cube((side*.18,0,.12),(.18,.34,.16),'ink')
            arm=cube((side*.38,0,.68),(.13,.16,.46),'card' if name=='banana' else 'moss' if name=='leaf' else 'ink')
            arm.rotation_euler[1]=side*.25
            sphere((side*.43,-.03,.48),(.105,.1,.11),'paper')
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts:o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.convert(target='MESH');bpy.ops.object.join();o=bpy.context.object;o.name=name
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    if name in ['banana','leaf','bottle','judge','battery','wrapper']:
        o.shape_key_add(name='Basis')
        for side,label in [(1,'StrideA'),(-1,'StrideB')]:
            key=o.shape_key_add(name=label)
            for v in key.data:
                x,y,z=v.co
                if z<.45:
                    v.co.y+=side*(1 if x>0 else -1)*(.45-z)*.5
                    v.co.z+=max(0,side*(1 if x>0 else -1))*(.45-z)*.12
                if abs(x)>.32 and z<1.2: v.co.y-=side*(1 if x>0 else -1)*.13
                v.co.x+=side*.035*z
            for frame,value in [(1,0),(7,1 if side==1 else 0),(13,0),(19,1 if side==-1 else 0),(25,0)]:
                key.value=value;key.keyframe_insert(data_path='value',frame=frame)
        o.data.shape_keys.animation_data.action.name=name+'_Walk'
    bpy.context.scene.frame_set(1)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,name+'.glb'),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_frame_range=True)
    o.location.x=len(bpy.data.objects)*0 # source layout is arranged later
    parts.clear();return o

assets=[]
bpy.context.scene.frame_start=1;bpy.context.scene.frame_end=25
# Curved organic character body and peeled ribbons.
verts=[];faces=[]
for j in range(9):
    t=j/8;cx=.28*math.sin(t*math.pi);z=.15+t*1.45;r=.14+.1*math.sin(t*math.pi)
    for k in range(8):
        a=k*math.tau/8;verts.append((cx+r*math.cos(a),r*math.sin(a),z))
for j in range(8):
    for k in range(8):a=j*8+k;b=j*8+(k+1)%8;faces.append((a,b,b+8,a+8))
mesh('banana body',verts,faces,'gold');cylinder((0,0,1.68),.07,.16,'card')
for side in [-1,1]:
    mesh('peel',[(side*.15,-.04,.8),(side*.28,.05,.8),(side*.63,.04,.4),(side*.7,-.1,.35),(side*.43,-.16,.6)],[(0,1,2,3,4)],'pale')
eyes(1.2,.10,-.2);assets.append(export('banana'))
# Leaf: thick silhouette with a central vein and cape-like lower leaves.
outline=[(0,1.75),(.28,1.45),(.41,1.25),(.32,1.16),(.44,.94),(.24,.66),(0,.4),(-.25,.66),(-.43,.94),(-.31,1.16),(-.4,1.28),(-.23,1.53)]
v=[(x,y,z) for y in [-.08,.08] for x,z in outline];n=len(outline);f=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
mesh('leaf',v,f,'leaf');cube((0,-.1,1),(.025,.02,.7),'moss',0);eyes(1.1,.13,-.11)
mesh('leaf cape',[(-.22,.12,1.05),(.22,.12,1.05),(.53,.20,.24),(.18,.22,.36),(0,.23,.2),(-.18,.22,.36),(-.53,.20,.24)],[(0,1,2,3,4,5,6)],'moss')
badge=cylinder((0,-.16,.70),.1,.06,'gold');badge.rotation_euler[0]=math.pi/2
cube((-.13,0,.22),(.16,.24,.2),'card');cube((.13,0,.22),(.16,.24,.2),'card');assets.append(export('leaf'))
# Ribbed opaque plastic bottle: no expensive transparent materials.
cylinder((0,0,.8),.25,1.0,'blue');sphere((0,0,1.33),(.23,.23,.23),'blue');cylinder((0,0,1.56),.13,.22,'cap')
for z in [.4,.6,.8,1.0]:cylinder((0,0,z),.275,.06,'blue')
for x in [-.12,.12]:cube((x,-.27,1.17),(.23,.06,.14),'ink');cube((x,-.02,.13),(.18,.3,.13),'paper')
cube((0,-.3,1.17),(.08,.05,.025),'ink',0);cube((0,-.26,.9),(.17,.03,.025),'paper',0);assets.append(export('bottle'))
# Judge Cardboard, robe, book, and gavel.
cube((0,0,1.37),(.72,.6,.64),'card');cube((0,0,.62),(.9,.6,.82),'ink');eyes(1.42,.17,-.325)
for x in [-.14,.14]:o=cube((x,-.33,.84),(.12,.035,.3),'paper');o.rotation_euler[1]=x*.6
cube((.48,-.06,.61),(.22,.17,.4),'card');cube((.55,-.18,.68),(.28,.14,.36),'purple');cube((-.58,0,.78),(.08,.1,.7),'card');o=cylinder((-.58,0,1.15),.16,.4,'card');o.rotation_euler[1]=math.pi/2
for x in [-.25,.25]:cube((x,-.06,.13),(.28,.4,.15),'card')
for x in [-.16,.16]:
    brow=cube((x,-.354,1.59),(.19,.025,.035),'ink',0);brow.rotation_euler[1]=x*1.8
assets.append(export('judge'))
# Battery, bag, sorting tool, aircraft, bins, modular planter.
cylinder((0,0,.7),.24,1.15,'ink');cylinder((0,0,1.3),.22,.13,'gold');cylinder((0,0,1.4),.1,.09,'metal');cube((0,-.246,.85),(.19,.015,.045),'gold',0);cube((0,-.246,.85),(.045,.015,.19),'gold',0);assets.append(export('battery'))
sphere((0,0,.62),(.42,.3,.55),'coral');cylinder((0,0,1.18),.1,.22,'ink');eyes(.76,.14,-.3);assets.append(export('wrapper'))
cube((0,0,0),(.34,.5,.25),'metal')
cube((0,.3,-.02),(.28,.28,.22),'ink')
for x in [-.09,.09]:
    barrel=cylinder((x,-.55,.03),.07,.75,'metal');barrel.rotation_euler[0]=math.pi/2
    muzzle=cylinder((x,-.96,.03),.09,.12,'ink');muzzle.rotation_euler[0]=math.pi/2
for y in [-.2,-.05,.1]:cube((0,y,.16),(.36,.07,.045),'ink')
cube((0,.12,-.28),(.15,.2,.4),'ink')
cube((.18,.03,-.20),(.14,.3,.22),'card')
cube((.175,-.04,.03),(.025,.18,.10),'leaf',0)
cube((0,-.26,.20),(.07,.08,.06),'gold')
assets.append(export('tool'))
mesh('ship',[(0,-.8,0),(-.5,.5,-.1),(-.16,.4,.16),(0,.05,.27),(.16,.4,.16),(.5,.5,-.1),(0,.65,-.06)],[(0,1,2,3),(0,3,4,5),(1,6,5),(1,5,4,2),(2,4,3)],'metal')
sphere((0,-.1,.14),(.18,.34,.14),'cap')
for x in [-.3,.3]:
    cube((x,.35,0),(.19,.37,.14),'gold');sphere((x,.59,0),(.08,.09,.08),'blue')
assets.append(export('ship'))
cube((0,0,.45),(.75,.65,.9),'moss');cube((0,0,.92),(.81,.71,.12),'paper');cube((0,-.335,.55),(.4,.02,.23),'blue',0);assets.append(export('bin'))
cube((0,0,.16),(.8,.8,.32),'card');cylinder((0,0,.64),.05,.8,'card');sphere((0,0,1.17),(.44,.44,.5),'leaf');assets.append(export('tree'))

# Editable source overview and a verification render.
for i,obj in enumerate(assets):obj.location=(i%5*2.1,(i//5)*2.5,0)
bpy.ops.object.camera_add(location=(5,-12,10));cam=bpy.context.object;cam.rotation_euler=(Vector((4,1,.6))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=12;bpy.context.scene.camera=cam
bpy.ops.object.light_add(type='AREA',location=(2,-4,8));bpy.context.object.data.energy=1700;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=7
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=12;scene.render.resolution_x=1000;scene.render.resolution_y=600;scene.render.resolution_percentage=100;scene.world.color=(.2,.2,.2);scene.render.image_settings.file_format='PNG';scene.render.filepath=os.path.join(ROOT,'docs','godot','asset-preview.png')
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE,'masthak-assets.blend'))
bpy.ops.render.render(write_still=True)
print('MASTHAK_ASSETS_OK',[(o.name,len(o.data.polygons)) for o in assets],flush=True)

# Original animated render strips for the flat games, created from the same 3D cast.
scene.render.resolution_x=160;scene.render.resolution_y=192;scene.render.film_transparent=True
scene.view_settings.view_transform='Standard';scene.view_settings.exposure=-.35
scene.cycles.samples=8
cam.location=(2.8,-7,2.7);cam.rotation_euler=(Vector((0,0,.9))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=2.1
characters=[o for o in assets if o.name in ['banana','leaf','bottle','judge','battery','wrapper']]
for obj in assets:obj.hide_render=True
def png_chunk(tag,data):return struct.pack('!I',len(data))+tag+data+struct.pack('!I',zlib.crc32(tag+data)&0xffffffff)
for obj in characters:
    obj.hide_render=False;original=obj.location.copy();obj.location=(0,0,0)
    strip=bytearray(160*8*192*4)
    for i in range(8):
        scene.frame_set(1+i*3);scene.render.filepath=os.path.join(OUT,'render-tmp.png');bpy.ops.render.render(write_still=True)
        frame_image=bpy.data.images.load(scene.render.filepath,check_existing=False)
        pixels=list(frame_image.pixels)
        for y in range(192):
            source=(191-y)*160*4;dest=(y*160*8+i*160)*4
            strip[dest:dest+160*4]=bytes(round(max(0,min(1,(v*12.92 if v<=.0031308 else 1.055*v**(1/2.4)-.055) if j%4!=3 else v))*255) for j,v in enumerate(pixels[source:source+160*4]))
        bpy.data.images.remove(frame_image)
    raw=b''.join(b'\0'+strip[y*160*8*4:(y+1)*160*8*4] for y in range(192))
    path=os.path.join(OUT,obj.name+'-walk.png')
    with open(path,'wb') as f:f.write(b'\x89PNG\r\n\x1a\n'+png_chunk(b'IHDR',struct.pack('!2I5B',1280,192,8,6,0,0,0))+png_chunk(b'IDAT',zlib.compress(raw,9))+png_chunk(b'IEND',b''))
    obj.hide_render=True;obj.location=original
    print('ANIMATED_STRIP',obj.name,flush=True)
os.remove(os.path.join(OUT,'render-tmp.png'))
