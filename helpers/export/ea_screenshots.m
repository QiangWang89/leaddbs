function ea_screenshots(uipatdir,handles,target)




options=ea_getptopts(uipatdir);
options.fiberthresh=1;
options.d3.verbose='on';
options.native=0;
[coords_mm,trajectory,markers,elmodel,manually_corrected,coords_acpc]=ea_load_reconstruction(options);
options.leadprod='dbs';
options.elmodel=elmodel;
[options]=ea_resolve_elspec(options);
options=ea_detsides(options);
options.d3.elrendering=1;
options.d3.hlactivecontacts=0;
options.d3.writeatlases=1;
options.d3.showisovolume=0;
viewsets=load([ea_getearoot,'helpers',filesep,'export',filesep,'ea_exportviews']);
options.atlasset=viewsets.(target).atlas;
options.sidecolor=1;
options.writeoutstats=0;
resultfig=ea_elvis(options);

if ~exist([options.root,options.patientname,filesep,'export',filesep,'views'],'dir')
    mkdir([options.root,options.patientname,filesep,'export',filesep,'views']);
end

views=viewsets.(target).views;
for view=1:length(views)
    set(0,'CurrentFigure',resultfig);
    ea_keepatlaslabels( views(view).structures{:});
    set(0,'CurrentFigure',resultfig);
    ea_setplanes(views(view).planes.x,views(view).planes.y,views(view).planes.z);
    set(0,'CurrentFigure',resultfig);
    ea_view(views(view).v);
    set(0,'CurrentFigure',resultfig);
    ea_screenshot([options.root,options.patientname,filesep,'export',filesep,'views',filesep,'view_',num2str(view),'.png'],'ld');
end
close(resultfig);







