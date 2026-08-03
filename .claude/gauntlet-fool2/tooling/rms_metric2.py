"""Revised R13 HP (sigma 6) and MID (sigma 6 minus sigma 40) image metric."""
import json, math, os, sys
import numpy as np
from PIL import Image
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),'..')); R=os.path.join(ROOT,'renders')
anchors={'upper_arm':('front',(516.2503,270.9376),(6.5625,5.25)),
 'abdomen':('front',(691.2502,356.2501),(15.3125,15.3125)),
 'costal':('front',(638.7502,347.5001),(17.5,10.9375)),
 'clavicle':('front',(649.6877,244.6876),(26.25,13.125)),
 'psis':('back',(667.1877,415.3126),(35.,17.5)),
 'belt':('back',(645.3127,384.6876),(17.5,17.5))}
def lum(path):
 a=np.asarray(Image.open(path).convert('RGB'),dtype=np.float32)/255.; return a@np.array([.2126,.7152,.0722])
def blur(a,s):
 rad=int(math.ceil(4*s)); q=np.arange(-rad,rad+1); k=np.exp(-.5*(q/s)**2); k/=k.sum()
 p=len(k)//2; x=np.pad(a,((0,0),(p,p)),mode='reflect'); x=np.apply_along_axis(lambda u:np.convolve(u,k,'valid'),1,x)
 x=np.pad(x,((p,p),(0,0)),mode='reflect'); return np.apply_along_axis(lambda u:np.convolve(u,k,'valid'),0,x)
out={}
for prefix in ('r13base','r13final','r13fix'):
 ims={v:lum(os.path.join(R,f'{prefix}-{v}-flat.png')) for v in ('front','back')}; out[prefix]={}
 for name,(view,(cx,cy),(rx,ry)) in anchors.items():
  a=ims[view]; b6=blur(a,6); b40=blur(a,40); yy,xx=np.ogrid[:a.shape[0],:a.shape[1]]; m=((xx-cx)/rx)**2+((yy-cy)/ry)**2<=1
  out[prefix][name]={'hp':float(np.sqrt(np.mean((a[m]-b6[m])**2))*255),'mid':float(np.sqrt(np.mean((b6[m]-b40[m])**2))*255),'n':int(m.sum())}
json.dump({'settings':{'bands':{'hp':'luminance-blur(sigma6)','mid':'blur(sigma6)-blur(sigma40)'},'units':'8-bit RMS'},'metrics':out},open(os.path.join(ROOT,'r13_rms2.json'),'w'),indent=2)
for p in out:
 for n,q in out[p].items(): print('RMS2',p,n,'HP %.6f MID %.6f'%(q['hp'],q['mid']))
