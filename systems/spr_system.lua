SprSystem=System({Spr,Pos}, function(ent)
 local spr,pos=ent[Spr],ent[Pos]
 if(not spr.enable)return
 SubmitSpr(SingletonEntity[DrawSystemData],spr.id,pos.x,pos.y,spr.layer,spr.width,spr.height,spr.flipX,spr.flipY)
end)