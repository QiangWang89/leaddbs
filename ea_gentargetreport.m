function ea_gentargetreport(M)



thresh = inputdlg('Please enter threshold in mm:','Enter threshold...',1,{'0.5'});

if isempty(thresh)
    return
end
thresh=str2double(thresh{1});


for thr=0:1
    
    for target=1:length(M.ui.volumeintersections)
        if thr
            rf(target,thr+1)=figure('color','w','Numbertitle','off','name',['Electrode centers residing in ',M.vilist{M.ui.volumeintersections(target)}]);
        else
            rf(target,thr+1)=figure('color','w','Numbertitle','off','name',['Distances of electrode centers to nearest voxel in ',M.vilist{M.ui.volumeintersections(target)}]);
        end
        distances=zeros(8,length(M.ui.listselect));
        
        for pt=1:length(M.ui.listselect)
            
            try
                distances(:,pt)=[M.stats(M.ui.listselect(pt)).ea_stats.conmat{1}(:,M.ui.volumeintersections(target));... % right side
                    M.stats(M.ui.listselect(pt)).ea_stats.conmat{2}(:,M.ui.volumeintersections(target))];
            catch
                ea_error('Please run DBS stats for all patients first.');
            end
            
            
        end
        
        if thr
            distances=distances<thresh;
        end
        
        
        R{target,thr+1}=distances;
        
        
        for xx=1:size(R{target,thr+1},1)
              for yy=1:size(R{target,thr+1},2)
                  side=ceil((xx/8)*2);
                  con=xx+(1-side)*size(R{target,thr+1},1)/2;
                  cstring='FFFFFF';
                  try
                      % if logical(M.stimparams(yy,side).U(con)) && M.ui.hlactivecontcheck
                      if logical(M.S(yy).activecontacts{side}(con)) && M.ui.hlactivecontcheck
                          cstring='FF9999';
                      end
                  end
                  C{xx,yy}=['<html><table border=0 width=400 bgcolor=#',cstring,'><TR><TD>',num2str(R{target,thr+1}(xx,yy)),'</TR> </table></html>'];
              end
        end
        
        cnames=M.patient.list(M.ui.listselect');
        [~,cnames]=cellfun(@fileparts,cnames,'UniformOutput',0);
        rnames={'K0','K1','K2','K3','K8','K9','K10','K11'};
        
        if        M.ui.hlactivecontcheck
            t(target,thr+1)=uitable(rf(target,thr+1),'Data',C,'ColumnName',cnames,'RowName',rnames);
        else
            t(target,thr+1)=uitable(rf(target,thr+1),'Data',R{target,thr+1},'ColumnName',cnames,'RowName',rnames);
        end
        figdims=get(rf(target,thr+1),'Position');
        textend=get(t(target,thr+1),'Extent');
        set(rf(target,thr+1),'Position',[figdims(1:2),textend(3:4)]);
        figdims=get(rf(target,thr+1),'Position');
        set(t(target,thr+1),'Position',[0,0,figdims(3),figdims(4)])
        
        
        
    end
end

assignin('base','R',R);
