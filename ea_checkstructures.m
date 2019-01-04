function varargout = ea_checkstructures(varargin)
% EA_CHECKSTRUCTURES MATLAB code for ea_checkstructures.fig
%      EA_CHECKSTRUCTURES, by itself, creates a new EA_CHECKSTRUCTURES or raises the existing
%      singleton*.
%
%      H = EA_CHECKSTRUCTURES returns the handle to a new EA_CHECKSTRUCTURES or the handle to
%      the existing singleton*.
%
%      EA_CHECKSTRUCTURES('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EA_CHECKSTRUCTURES.M with the given input arguments.
%
%      EA_CHECKSTRUCTURES('Property','Value',...) creates a new EA_CHECKSTRUCTURES or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ea_checkstructures_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ea_checkstructures_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ea_checkstructures

% Last Modified by GUIDE v2.5 01-Dec-2018 10:59:10

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ea_checkstructures_OpeningFcn, ...
                   'gui_OutputFcn',  @ea_checkstructures_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before ea_checkstructures is made visible.
function ea_checkstructures_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ea_checkstructures (see VARARGIN)

% Choose default command line output for ea_checkstructures
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);





set(handles.checkstructures,'Name','Check registration of specific structures.');



% add atlases contextmenu

options=varargin{1};
setappdata(handles.checkstructures,'options',options);
setappdata(handles.checkstructures,'hemisphere',2);
setappdata(handles.checkstructures,'offset',[0.5,0.5,0.5]);
[~,presentfiles]=ea_assignpretra(options);

c = uicontextmenu(handles.checkstructures);
handles.otherstructures.UIContextMenu = c;
atlases=dir(ea_space(options,'atlases'));
atlases = {atlases(cell2mat({atlases.isdir})).name};    % only keep folders
atlases = atlases(cellfun(@(x) ~strcmp(x(1),'.'), atlases));  % also remove '.', '..' and '.*' folders from dir results
atlmenu=cell(length(presentfiles),length(atlases));
warning('off');

for atl=1:length(atlases)
    if ~exist([ea_space(options,'atlases'),atlases{atl},filesep,'atlas_index.mat'],'file')
        continue
    end
    atlmenu{atl}=uimenu('Parent',c,'Label',atlases{atl});
    clear a
    
    a=load([ea_space(options,'atlases'),atlases{atl},filesep,'atlas_index.mat'],'structures');
    if isempty(fieldnames(a)) % old format
        disp(['Re-indexing ',atlases{atl},'...']);
        a=load([ea_space(options,'atlases'),atlases{atl},filesep,'atlas_index.mat']);
        a.structures=a.atlases.names;
        save([ea_space(options,'atlases'),atlases{atl},filesep,'atlas_index.mat'],'-struct','a','-v7.3');
    end
    a.structures=ea_rmext(a.structures);
    try
        for strct=1:length(a.structures)
            structmenu{atl,strct}=uimenu('Parent',atlmenu{atl},'Label',a.structures{strct},'Callback',{@ea_setnewatlas,options,handles});
        end
    catch
        keyboard
    end
end

warning('on');
axes(handles.tra);
imshow(zeros(10,10,3));
axis equal
axis off
axes(handles.cor);
imshow(zeros(10,10,3));
axis equal
axis off
axes(handles.sag);
imshow(zeros(10,10,3));
axis equal
axis off
drawnow
% add preop acquisitions to popup
cellentr=cell(0);
for p=presentfiles'
   cellentr{end+1}=upper(p{1}(6:end-4));
end
set(handles.anat_select,'String',cellentr);
modality=get(handles.anat_select,'String');
modality=modality{get(handles.anat_select,'Value')};
setappdata(handles.checkstructures,'modality',modality);
options.prefs=ea_prefs(options.patientname);
switch(options.prefs.machine.checkreg.default)
    case 'DISTAL Minimal (Ewert 2017)@STN'
        ea_preset_stn(handles)
    case 'DISTAL Minimal (Ewert 2017)@GPi'
        ea_preset_gpi(handles)
    otherwise
        parts=ea_strsplit(options.prefs.machine.checkreg.default,'@');
        h.Parent.Label=parts{1};
        h.Label=parts{2};
        ea_setnewatlas(h,[],options,handles);
end

% UIWAIT makes ea_checkstructures wait for user response (see UIRESUME)
% uiwait(handles.checkstructures);


function ea_preset_stn(handles)
set(handles.stn,'Value',1); set(handles.gpi,'Value',0);
stnmods={'T2','QSM','T2STAR','FGATIR'};
mods=get(handles.anat_select,'String');
[is,idx]=ismember(mods,stnmods);
if any(is) % only change modality if theres a suitable one available.
    [~,sorted]=sort(idx,'ascend');
    for mod=sorted'
        if is(mod)
            bestmod=mod;
            break
        end
    end
    set(handles.anat_select,'Value',bestmod);
    ea_setnewbackdrop(handles,1);
end
options=getappdata(handles.checkstructures,'options');
h.Parent.Label='DISTAL Minimal (Ewert 2017)';
h.Label='STN';
ea_setnewatlas(h,[],options,handles)

function ea_preset_gpi(handles)
set(handles.stn,'Value',0); set(handles.gpi,'Value',1);
gpimods={'FGATIR','IR','T1','PD','QSM'};
mods=get(handles.anat_select,'String');
[is,idx]=ismember(mods,gpimods);
if any(is) % only change modality if theres a suitable one available.
    [~,sorted]=sort(idx,'ascend');
    for mod=sorted'
        if is(mod)
            bestmod=mod;
            break
        end
    end
    set(handles.anat_select,'Value',bestmod);
    ea_setnewbackdrop(handles,1);
end
options=getappdata(handles.checkstructures,'options');

h.Parent.Label='DISTAL Minimal (Ewert 2017)';
h.Label='GPi';
ea_setnewatlas(h,[],options,handles)

function ea_setnewbackdrop(handles,dontupdate)
modality=get(handles.anat_select,'String');
modality=modality{get(handles.anat_select,'Value')};
setappdata(handles.checkstructures,'modality',modality);
if ~exist('dontupdate','var')
    options=getappdata(handles.checkstructures,'options');
        ea_updateviews(options,handles,1:3)
end

function ea_setnewhemisphere(handles,dontupdate)
hemisphere=get(handles.rh,'Value');
if ~hemisphere % LH
    hemisphere=2;
end
setappdata(handles.checkstructures,'hemisphere',hemisphere);
if ~exist('dontupdate','var')
    options=getappdata(handles.checkstructures,'options');
    ea_setnewatlas([],[],options,handles,1);
    ea_updateviews(options,handles,3)
end

function ea_setnewatlas(h,gf,options,handles,dontupdate)
if isempty(h)
    h=getappdata(handles.checkstructures,'h');
end

ea_setprefs('checkreg.default',[h.Parent.Label,'@',h.Label]);

options.atlasset=h.Parent.Label;
load([ea_space(options,'atlases'),options.atlasset,filesep,'atlas_index.mat']);
[~,six]=ismember(h.Label,ea_rmext(atlases.names));
fv=atlases.fv(six,:);
pixdim=atlases.pixdim(six,:);


if length(fv)>1
    xyz=[fv{1}.vertices;fv{2}.vertices];
    pixdim=mean([pixdim{1};pixdim{2}]);
else
    xyz=fv{1}.vertices;
    pixdim=pixdim{1};
end

mz=mean(xyz);
vmz=abs(max(xyz)-min(xyz));
hemisphere=getappdata(handles.checkstructures,'hemisphere');
if hemisphere==1
    xyz=xyz(xyz(:,1)>0,:);
elseif hemisphere==2
    xyz=xyz(xyz(:,1)<0,:);
end
mzsag=mean(xyz);
vmzsag=abs(max(xyz)-min(xyz));


setappdata(handles.checkstructures,'h',h);
setappdata(handles.checkstructures,'fv',fv);
setappdata(handles.checkstructures,'atlases',atlases);
setappdata(handles.checkstructures,'pixdim',pixdim);
setappdata(handles.checkstructures,'mz',mz);
setappdata(handles.checkstructures,'mzsag',mzsag);
setappdata(handles.checkstructures,'vmz',vmz);
setappdata(handles.checkstructures,'vmzsag',vmzsag);
if ~exist('dontupdate','var')
        ea_updateviews(options,handles,1:3)
end

function ea_updateviews(options,handles,cortrasag)
fv=getappdata(handles.checkstructures,'fv');
atlases=getappdata(handles.checkstructures,'atlases');
pixdim=getappdata(handles.checkstructures,'pixdim');
mz=getappdata(handles.checkstructures,'mz');
mzsag=getappdata(handles.checkstructures,'mzsag');
vmz=getappdata(handles.checkstructures,'vmz');
vmzsag=getappdata(handles.checkstructures,'vmzsag');

h=getappdata(handles.checkstructures,'h');
views={'tra','cor','sag'};
for cts=cortrasag
    options.d2.writeatlases=1;
    options.d2.col_overlay=0;
    options.d2.con_color=[0.8,0.1,0];
    options.d2.atlasopacity=0.2;
    options.d2.tracor=cts;
    options.d2.bbsize=(max(vmz)/1.7);
    offset=getappdata(handles.checkstructures,'offset')-0.5;
    if cts<3
        mz(ea_view2coord(cts))=mz(ea_view2coord(cts))+offset(ea_view2coord(cts)).*vmz(ea_view2coord(cts));
        options.d2.depth=mz;
    else
        mzsag(ea_view2coord(cts))=mzsag(ea_view2coord(cts))+offset(ea_view2coord(cts)).*vmzsag(ea_view2coord(cts));
        options.d2.depth=mzsag;
    end
    options.d2.showlegend=0;
    options.d2.showstructures={h.Label};
    modality=getappdata(handles.checkstructures,'modality');

    [Vtra,Vcor,Vsag]=ea_assignbackdrop(['Patient Pre-OP (',modality,')'],options,'Patient');
    Vs={Vtra,Vcor,Vsag};
    options.sides=1;
    evalin('base','custom_cont=2;');
    [hf,img]=ea_writeplanes(options,options.d2.depth,options.d2.tracor,Vs{options.d2.tracor},'off',2);
    axes(handles.(views{cts}));
    imshow(img);
end

function coord=ea_view2coord(view)
switch view
    case 1
        coord=3;
    case 2
        coord=2;
    case 3
        coord=1;
end

% --- Outputs from this function are returned to the command line.
function varargout = ea_checkstructures_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in stn.
function stn_Callback(hObject, eventdata, handles)
% hObject    handle to stn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value')
    ea_preset_stn(handles);
end

% --- Executes on button press in gpi.
function gpi_Callback(hObject, eventdata, handles)
% hObject    handle to gpi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value')
    ea_preset_gpi(handles);
end

% --- Executes on button press in otherstructures.
function otherstructures_Callback(hObject, eventdata, handles)
% hObject    handle to otherstructures (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.stn,'Value',0); set(handles.gpi,'Value',0);

CurPos = get(0, 'PointerLocation');
figPos = get(gcf,'Position');
handles.otherstructures.UIContextMenu.Position = CurPos - figPos(1:2);
handles.otherstructures.UIContextMenu.Visible='on';

% --- Executes on selection change in anat_select.
function anat_select_Callback(hObject, eventdata, handles)
% hObject    handle to anat_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns anat_select contents as cell array
%        contents{get(hObject,'Value')} returns selected item from anat_select
ea_setnewbackdrop(handles);


% --- Executes during object creation, after setting all properties.
function anat_select_CreateFcn(hObject, eventdata, handles)
% hObject    handle to anat_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function traslide_Callback(hObject, eventdata, handles)
% hObject    handle to traslide (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
setappdata(handles.checkstructures,'offset',[get(handles.sagslide,'Value'),get(handles.corslide,'Value'),get(handles.traslide,'Value')]);
options=getappdata(handles.checkstructures,'options');
ea_updateviews(options,handles,1);


% --- Executes during object creation, after setting all properties.
function traslide_CreateFcn(hObject, eventdata, handles)
% hObject    handle to traslide (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function corslide_Callback(hObject, eventdata, handles)
% hObject    handle to corslide (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
setappdata(handles.checkstructures,'offset',[get(handles.sagslide,'Value'),get(handles.corslide,'Value'),get(handles.traslide,'Value')]);
options=getappdata(handles.checkstructures,'options');
ea_updateviews(options,handles,2);

% --- Executes during object creation, after setting all properties.
function corslide_CreateFcn(hObject, eventdata, handles)
% hObject    handle to corslide (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sagslide_Callback(hObject, eventdata, handles)
% hObject    handle to sagslide (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
setappdata(handles.checkstructures,'offset',[get(handles.sagslide,'Value'),get(handles.corslide,'Value'),get(handles.traslide,'Value')]);
options=getappdata(handles.checkstructures,'options');
ea_updateviews(options,handles,3);

% --- Executes during object creation, after setting all properties.
function sagslide_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sagslide (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in lh.
function lh_Callback(hObject, eventdata, handles)
% hObject    handle to lh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of lh
set(handles.rh,'Value',0);
ea_setnewhemisphere(handles);


% --- Executes on button press in rh.
function rh_Callback(hObject, eventdata, handles)
% hObject    handle to rh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rh
set(handles.lh,'Value',0);
ea_setnewhemisphere(handles);