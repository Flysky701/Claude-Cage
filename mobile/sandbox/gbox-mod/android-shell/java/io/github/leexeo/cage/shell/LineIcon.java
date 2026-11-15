package io.github.leexeo.cage.shell;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.view.View;

/** Small native line icons on a consistent 24px grid, matching the desktop icon weight. */
final class LineIcon extends View {
    private final String kind;
    private final Paint pen=new Paint(Paint.ANTI_ALIAS_FLAG);
    LineIcon(Context context,String kind,int color){super(context);this.kind=kind;pen.setColor(color);pen.setStrokeWidth(1.65f);pen.setStyle(Paint.Style.STROKE);pen.setStrokeCap(Paint.Cap.ROUND);pen.setStrokeJoin(Paint.Join.ROUND);setImportantForAccessibility(IMPORTANT_FOR_ACCESSIBILITY_NO);}
    private void line(Canvas c,float... p){Path path=new Path();path.moveTo(p[0],p[1]);for(int i=2;i<p.length;i+=2)path.lineTo(p[i],p[i+1]);c.drawPath(path,pen);}
    private void rect(Canvas c,float a,float b,float d,float e,float r){c.drawRoundRect(new RectF(a,b,d,e),r,r,pen);}
    @Override protected void onDraw(Canvas c){super.onDraw(c);c.save();float size=Math.min(getWidth(),getHeight());c.translate((getWidth()-size)/2,(getHeight()-size)/2);c.scale(size/24,size/24);
        switch(kind){
            case "space": line(c,12,3,21,8,21,17,12,22,3,17,3,8,12,3);line(c,3,8,12,13,21,8);line(c,12,13,12,22);break;
            case "shield": {Path p=new Path();p.moveTo(12,3);p.lineTo(21,6);p.lineTo(21,12);p.cubicTo(21,17,16,20,12,22);p.cubicTo(8,20,3,17,3,12);p.lineTo(3,6);p.close();c.drawPath(p,pen);line(c,8,12,11,15,16,9);break;}
            case "settings": c.drawCircle(12,12,3,pen);for(int i=0;i<8;i++){c.save();c.rotate(i*45,12,12);line(c,12,2,12,4);c.restore();}c.drawCircle(12,12,8,pen);break;
            case "clock":c.drawCircle(12,12,9,pen);line(c,12,7,12,12,15,14);break;
            case "globe":c.drawCircle(12,12,9,pen);c.drawOval(new RectF(8,3,16,21),pen);line(c,3,12,21,12);break;
            case "sim":line(c,8,3,18,3,20,5,20,21,4,21,4,7,8,3);rect(c,8,10,16,17,1);line(c,8,13.5f,16,13.5f);line(c,12,10,12,17);break;
            case "check":line(c,5,12,10,17,19,7);break;
            case "close":line(c,6,6,18,18);line(c,18,6,6,18);break;
            case "help":c.drawCircle(12,12,9,pen);{Path p=new Path();p.moveTo(9,9);p.cubicTo(9,5,16,6,15,10);p.cubicTo(15,12,12,12,12,14);c.drawPath(p,pen);}c.drawPoint(12,17,pen);break;
            case "info":c.drawCircle(12,12,9,pen);line(c,12,11,12,17);c.drawPoint(12,7,pen);break;
            case "chevron":line(c,9,5,16,12,9,19);break;
            case "down":line(c,5,9,12,16,19,9);break;
            case "up":line(c,5,15,12,8,19,15);break;
            case "plus":line(c,12,5,12,19);line(c,5,12,19,12);break;
            case "arrow":line(c,4,12,20,12);line(c,14,6,20,12,14,18);break;
            case "refresh":c.drawArc(new RectF(4,4,20,20),35,285,false,pen);line(c,19,3,19,8,14,8);break;
            case "user":c.drawCircle(12,8,4,pen);{Path p=new Path();p.moveTo(4,21);p.cubicTo(4,12,20,12,20,21);c.drawPath(p,pen);}break;
            case "theme":c.drawCircle(12,12,9,pen);pen.setStyle(Paint.Style.FILL);c.drawArc(new RectF(3,3,21,21),90,180,true,pen);pen.setStyle(Paint.Style.STROKE);break;
            case "copy":rect(c,8,8,21,21,2);line(c,5,16,3,16,3,3,16,3,16,5);break;
            case "pause":line(c,8,5,8,19);line(c,16,5,16,19);break;
            default:rect(c,4,4,20,20,4);line(c,8,9,16,9);line(c,8,14,13,14);
        }c.restore();
    }
}
