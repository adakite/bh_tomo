function varargout = bh_tomo_contraintes(varargin)
% BH_TOMO_CONTRAINTES M-file for bh_tomo_contraintes.fig
%      BH_TOMO_CONTRAINTES, by itself, creates a new BH_TOMO_CONTRAINTES or raises the existing
%      singleton*.
%
%      H = BH_TOMO_CONTRAINTES returns the handle to a new BH_TOMO_CONTRAINTES or the handle to
%      the existing singleton*.
%
%      BH_TOMO_CONTRAINTES('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BH_TOMO_CONTRAINTES.M with the given input arguments.
%
%      BH_TOMO_CONTRAINTES('Property','Value',...) creates a new BH_TOMO_CONTRAINTES or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before bh_tomo_contraintes_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to bh_tomo_contraintes_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright (C) 2005 Bernard Giroux
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
% 
%

% Edit the above text to modify the response to help bh_tomo_contraintes

% Last Modified by GUIDE v2.5 21-Mar-2013 14:19:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @bh_tomo_contraintes_OpeningFcn, ...
    'gui_OutputFcn',  @bh_tomo_contraintes_OutputFcn, ...
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


% --- Executes just before bh_tomo_contraintes is made visible.
function bh_tomo_contraintes_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to bh_tomo_contraintes (see VARARGIN)

% Choose default command line output for bh_tomo_contraintes
handles.output = hObject;
handles.second_output = [];

% Update handles structure
guidata(hObject, handles);

h.grx = [-0.2 0.2 1];
h.grz = [-0.2 0.2 2];
h.n_vitesse = 0.1;
h.n_att = 1;
h.v_air = 0.2998;    % vitesse ds air
h.a_air = 0;      % attenuation ds air
h.f = [];
h.v_couche_inf = 0.12;
h.a_couche_inf = 0.5;
h.change_plot = true;
h.cont_orig = [];
h.plan = [];

if nargin>=8
    h.plan = varargin{5};
end
if nargin>=7
    h.cont_orig = varargin{4};
end
if nargin>=6
    tmp = varargin{3}; % [xTx zTx xRx zRx ...]
    str = cell(1,(numel(tmp)/2));
    for n=1:(numel(tmp)/2)
        h.f(n).x = tmp( 2*n-1 );
        h.f(n).z = tmp( 2*n );
        str{n} = num2str(n);
    end
    set(handles.edit_nf, 'String', num2str(length(h.f)))
    set(handles.popupmenu_f_no, 'String', str)
    set(handles.edit_x_f, 'String', num2str(h.f(1).x))
    set(handles.edit_z_f, 'String', num2str(h.f(1).z))
end
if nargin>=5
    h.grz = varargin{2};
end
if nargin>=4
    h.grx = varargin{1};
end
str = get_str_locale();

x=(h.grx(1):h.grx(2):h.grx(3))';
z=(h.grz(1):h.grz(2):h.grz(3))';

ind1=2:length(x);
ind2=1:length(x)-1;
h.gridx=(x(ind2)+x(ind1))/2;
ind1=2:length(z);
ind2=1:length(z)-1;
h.gridz=(z(ind2)+z(ind1))/2;

h.vitesse = nan(length(h.gridz), length(h.gridx));

DX = h.grx(2);
DZ = h.grz(2);
h.xx = (h.grx(1)+DX/2):DX:(h.grx(3)-DX/2);
h.zz = (h.grz(1)+DZ/2):DZ:(h.grz(3)-DZ/2);
h.SW = nan(length(h.zz), length(h.xx));
h.XI = nan(length(h.zz), length(h.xx));
h.ATT = h.SW;
h.VAR_S = h.SW;
h.VAR_xi = h.SW;
h.VAR_A = h.SW;
h.RES = zeros(length(h.zz), length(h.xx));
h.variance_s = 1;
h.variance_a = 0.25;
[h.XX,h.ZZ] = meshgrid(h.xx,h.zz);

h.aa = [min(x)*ones(length(z),1) max(x)*ones(length(z),1);x x]';
h.bb = [z z; min(z)*ones(length(x),1) max(z)*ones(length(x),1)]';

if ~isempty( h.cont_orig.slowness )
    s = h.cont_orig.slowness.data;
    for n=1:size(s,1)
        ix = findnear(s(n,2), h.xx);
        iz = findnear(s(n,1), h.zz);
        h.SW(iz,ix) = s(n,3);
        if size(s,2)==4
            h.VAR_S(iz,ix) = s(n,4);
        else
            h.VAR_S(iz,ix) = 0;
        end
    end
    if isfield( h.cont_orig.slowness, 'data_xi' )
        s = h.cont_orig.slowness.data_xi;
        for n=1:size(s,1)
            ix = findnear(s(n,2), h.xx);
            iz = findnear(s(n,1), h.zz);
            h.XI(iz,ix) = s(n,3);
            if size(s,2)==4
                h.VAR_xi(iz,ix) = s(n,4);
            else
                h.VAR_xi(iz,ix) = 0;
            end
        end
    end
end

if ~isempty( h.cont_orig.attenuation )
    s = h.cont_orig.attenuation.data;
    for n=1:size(s,1)
        ix = findnear(s(n,2), h.xx);
        iz = findnear(s(n,1), h.zz);
        h.ATT(iz,ix) = s(n,3);
        if size(s,2)==4
            h.VAR_A(iz,ix) = s(n,4);
        else
            h.VAR_A(iz,ix) = 0;
        end
    end
    if isfield( h.cont_orig.slowness, 'variance' )
        h.variance_s = h.cont_orig.slowness.variance;
    end
    if isfield( h.cont_orig.attenuation, 'variance' )
        h.variance_a = h.cont_orig.attenuation.variance;
    end
end

if isfield( h.cont_orig,'ind_reservoir')
    h.RES = h.cont_orig.ind_reservoir;
end

set(handles.edit_v_inf,'string',num2str(h.v_couche_inf))
set(handles.edit_variance_cont,'String',num2str(h.variance_s))

setappdata(handles.fig_bh_cont, 'h', h)
setappdata(handles.fig_bh_cont, 'str', str)
set_str_locale(handles)
update_fig(handles)
edit_cmax_Callback(hObject, eventdata, handles);  %%YH
edit_cmin_Callback(hObject, eventdata, handles);  %%YH
ToolTip = sprintf('Left click mouse to edit the grid\nRight click mouse to stop edit.');
set(handles.pushbutton_edit,'ToolTipString',ToolTip); %%YH
% UIWAIT makes bh_tomo_contraintes wait for user response (see UIRESUME)
uiwait(handles.fig_bh_cont);

% --- Outputs from this function are returned to the command line.
function varargout = bh_tomo_contraintes_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

varargout{1} = handles.output;
varargout{2} = handles.second_output;
delete(hObject);

function edit_valeur_Callback(hObject, eventdata, handles)
h = getappdata(handles.fig_bh_cont, 'h');
h.n_vitesse = str2double(get(hObject,'String'));
setappdata(handles.fig_bh_cont, 'h', h)


function edit_valeur_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function pushbutton_edit_Callback(hObject, eventdata, handles)
if get(handles.radiobutton_vel,'Value')==1
	edit_SW(handles)
elseif get(handles.radiobutton_att,'Value')==1
    edit_ATT(handles)
else
    edit_RES(handles)
end


function pushbutton_save_Callback(hObject, eventdata, handles)
cont = prepare_cont(handles);
[fichier,rep]=uiputfile('*.dat','Fichier contraintes');
fid=fopen([rep,fichier],'wt');
if get(handles.radiobutton_vel,'Value')==1
    fprintf(fid,'%f     %f     %f     %d\n', cont.slowness.data);
else
    fprintf(fid,'%f     %f     %f     %d\n', cont.attenuation.data);
end
fclose(fid);


function pushbutton_quit_Callback(hObject, eventdata, handles)
handles.second_output = prepare_cont(handles);
guidata(hObject, handles);
uiresume(handles.fig_bh_cont);


function edit_nf_Callback(hObject, eventdata, handles)
% val = str2double(get(hObject,'string'));
% if isnan(val)
%     str = getappdata(handles.fig_bh_cont, 'str');
%     errordlg(str.s54)
% 	return
% end
% h = getappdata(handles.fig_bh_cont, 'h');

% setappdata(handles.fig_bh_cont, 'h', h)

function edit_nf_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_x_f_Callback(hObject, eventdata, handles)
% val = str2double(get(hObject,'string'));
% if isnan(val)
%     str = getappdata(handles.fig_bh_cont, 'str');
%     errordlg(str.s54)
% 	return
% end
% h = getappdata(handles.fig_bh_cont, 'h');
% h.xRx = val;
% setappdata(handles.fig_bh_cont, 'h', h)


function edit_x_f_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function popupmenu_f_no_Callback(hObject, eventdata, handles)
h = getappdata(handles.fig_bh_cont, 'h');
no = get(hObject,'Value');
set(handles.edit_x_f, 'String', num2str(h.f(no).x))
set(handles.edit_z_f, 'String', num2str(h.f(no).z))


function popupmenu_f_no_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_z_f_Callback(hObject, eventdata, handles)
% val = str2double(get(hObject,'string'));
% if isnan(val)
%     str = getappdata(handles.fig_bh_cont, 'str');
%     errordlg(str.s54)
% 	return
% end
% h = getappdata(handles.fig_bh_cont, 'h');
% h.zRx = val;
% setappdata(handles.fig_bh_cont, 'h', h)


function edit_z_f_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function checkbox_c_infer_Callback(hObject, eventdata, handles)
h = getappdata(handles.fig_bh_cont, 'h');
s2=nan;
if get(hObject,'Value')==1
    if get(handles.radiobutton_vel,'Value')==1
        s2 = 1/h.v_couche_inf;
    else
        s2 = h.a_couche_inf;
    end
end
if get(handles.radiobutton_vel,'Value')==1
    DATA = h.SW;
    VAR = h.VAR_S;
    variance = h.variance_s;
else
    DATA = h.ATT;
    VAR = h.VAR_A;
    variance = h.variance_a;
end

ascending = 0;
if h.f(2).x>h.f(1).x
    ascending = 1;
end


pas_legacy=1;

if ascending == 1
    % a gauche
    xs = h.xx( h.xx<h.f(1).x );
    if ~isempty(xs)
        zs = h.f(1).z*ones(size(xs));
        for nn=1:length(xs)
            [ii,jj] = find( h.XX==xs(nn) & h.ZZ<zs(nn) );
            ni = length(ii);
            DATA( ii((ni-pas_legacy+1):ni),jj(1:pas_legacy) ) = s2;
            VAR( ii((ni-pas_legacy+1):ni),jj(1:pas_legacy) ) = variance;
        end
    end
    for n=1:(length(h.f)-1)
        % la surface
        xs = h.xx( h.xx>=h.f(n).x & h.xx<=h.f(n+1).x );
        if isempty(xs)
            return
        end
        dx = xs(length(xs))-xs(1);
        dz = h.f(n+1).z-h.f(n).z;
        zs = h.f(n).z + dz/dx*(xs-h.f(n).x);
        % au dessous
        for nn=1:length(xs)
            [ii,jj] = find( h.XX==xs(nn) & h.ZZ<zs(nn) );
            ni = length(ii);
            DATA( ii((ni-pas_legacy+1):ni),jj(1:pas_legacy) ) = s2;
            VAR( ii((ni-pas_legacy+1):ni),jj(1:pas_legacy) ) = variance;
        end
    end
    % a droite
    xs = h.xx( h.xx>h.f(length(h.f)).x );
    if ~isempty(xs)
        zs = h.f(length(h.f)).z*ones(size(xs));
        for nn=1:length(xs)
            [ii,jj] = find( h.XX==xs(nn) & h.ZZ<zs(nn) );
            ni = length(ii);
            DATA( ii((ni-pas_legacy+1):ni),jj(1:pas_legacy) ) = s2;
            VAR( ii((ni-pas_legacy+1):ni),jj(1:pas_legacy) ) = variance;
        end
    end
else
    % a gauche
    xs = h.xx( h.xx<h.f(length(h.f)).x );
    if ~isempty(xs)
        zs = h.f(1).z*ones(size(xs));
        for nn=1:length(xs)
            [ii,jj] = find( h.XX==xs(nn) & h.ZZ<zs(nn) );
            ni = length(ii);
            DATA( ii((ni-pas_legacy+1):ni),jj(1:pas_legacy) ) = s2;
            VAR( ii((ni-pas_legacy+1):ni),jj(1:pas_legacy) ) = variance;
        end
    end
    for n=1:(length(h.f)-1)
        % la surface
        xs = h.xx( h.xx>=h.f(n+1).x & h.xx<=h.f(n).x );
        if isempty(xs)
            return
        end
        dx = xs(length(xs))-xs(1);
        dz = h.f(n+1).z-h.f(n).z;
        zs = h.f(n).z + dz/dx*(xs-h.f(n).x);
        % au dessous
        for nn=1:length(xs)
            [ii,jj] = find( h.XX==xs(nn) & h.ZZ<zs(nn) );
            ni = length(ii);
            DATA( ii((ni-pas_legacy+1):ni),jj(1:pas_legacy) ) = s2;
            VAR( ii((ni-pas_legacy+1):ni),jj(1:pas_legacy) ) = variance;
        end
    end
    % a droite
    xs = h.xx( h.xx>h.f(1).x );
    if ~isempty(xs)
        zs = h.f(length(h.f)).z*ones(size(xs));
        for nn=1:length(xs)
            [ii,jj] = find( h.XX==xs(nn) & h.ZZ<zs(nn) );
            ni = length(ii);
            DATA( ii((ni-pas_legacy+1):ni),jj(1:pas_legacy) ) = s2;
            VAR( ii((ni-pas_legacy+1):ni),jj(1:pas_legacy) ) = variance;
        end
    end
end
if get(handles.radiobutton_vel,'Value')==1
    h.SW = DATA;
    h.VAR_S = VAR;
else
    h.ATT = DATA;
    h.VAR_A = VAR;
end
setappdata(handles.fig_bh_cont, 'h', h)
update_fig(handles)


function edit_v_inf_Callback(hObject, eventdata, handles)
h = getappdata(handles.fig_bh_cont, 'h');
if get(handles.radiobutton_vel,'Value')==1
    h.v_couche_inf = str2double(get(hObject,'String'));
elseif get(handles.radiobutton_att,'Value')==1
    h.a_couche_inf = str2double(get(hObject,'String'));
end
setappdata(handles.fig_bh_cont, 'h', h)


function edit_v_inf_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function togglebutton_zoom_Callback(hObject, eventdata, handles)
button_state = get(hObject,'Value');
if button_state == get(hObject,'Max')
    zoom(handles.fig_bh_cont,'on')
elseif button_state == get(hObject,'Min')
    zoom(handles.fig_bh_cont,'off')
end

function pushbutton_zReset_Callback(hObject, eventdata, handles)
zoom(handles.fig_bh_cont,'out')

function checkbox_contSurf_Callback(hObject, eventdata, handles)
h = getappdata(handles.fig_bh_cont, 'h');
s1=nan;
if get(hObject,'Value')==1
    if get(handles.radiobutton_vel,'Value')==1
        s1 = 1/h.v_air;
    else
        s1 = h.a_air;
    end
end
if get(handles.radiobutton_vel,'Value')==1
    DATA = h.SW;
    VAR = h.VAR_S;
else
    DATA = h.ATT;
    VAR = h.VAR_A;
end

ascending = 0;
if h.f(2).x>h.f(1).x
    ascending = 1;
end

if ascending==1
    % a gauche
    xs = h.xx( h.xx<h.f(1).x );
    if ~isempty(xs)
        zs = h.f(1).z*ones(size(xs));
        for n=1:length(xs)
            DATA( h.XX==xs(n) & h.ZZ>=zs(n) ) = s1;
            VAR( h.XX==xs(n) & h.ZZ>=zs(n) ) = 0;
        end
    end
    for n=1:(length(h.f)-1)
        % au dessus de la surface
        xs = h.xx( h.xx>=h.f(n).x & h.xx<=h.f(n+1).x );
        if isempty(xs)
            return
        end
        dx = xs(length(xs))-xs(1);
        dz = h.f(n+1).z-h.f(n).z;
        zs = h.f(n).z + dz/dx*(xs-h.f(n).x);
        for nn=1:length(xs)
            DATA( h.XX==xs(nn) & h.ZZ>=zs(nn) ) = s1;
            VAR( h.XX==xs(nn) & h.ZZ>=zs(nn) ) = 0;
        end
    end
    % a droite
    xs = h.xx( h.xx>h.f(length(h.f)).x );
    if ~isempty(xs)
        zs = h.f(length(h.f)).z*ones(size(xs));
        for n=1:length(xs)
            DATA( h.XX==xs(n) & h.ZZ>=zs(n) ) = s1;
            VAR( h.XX==xs(n) & h.ZZ>=zs(n) ) = 0;
        end
    end
else
% a gauche
    xs = h.xx( h.xx<h.f(length(h.f)).x );
    if ~isempty(xs)
        zs = h.f(1).z*ones(size(xs));
        for n=1:length(xs)
            DATA( h.XX==xs(n) & h.ZZ>=zs(n) ) = s1;
            VAR( h.XX==xs(n) & h.ZZ>=zs(n) ) = 0;
        end
    end
    for n=1:(length(h.f)-1)
        % au dessus de la surface
        xs = h.xx( h.xx>=h.f(n+1).x & h.xx<=h.f(n).x );
        if isempty(xs)
            return
        end
        dx = xs(length(xs))-xs(1);
        dz = h.f(n+1).z-h.f(n).z;
        zs = h.f(n).z + dz/dx*(xs-h.f(n).x);
        for nn=1:length(xs)
            DATA( h.XX==xs(nn) & h.ZZ>=zs(nn) ) = s1;
            VAR( h.XX==xs(nn) & h.ZZ>=zs(nn) ) = 0;
        end
    end
    % a droite
    xs = h.xx( h.xx>h.f(1).x );
    if ~isempty(xs)
        zs = h.f(length(h.f)).z*ones(size(xs));
        for n=1:length(xs)
            DATA( h.XX==xs(n) & h.ZZ>=zs(n) ) = s1;
            VAR( h.XX==xs(n) & h.ZZ>=zs(n) ) = 0;
        end
    end
end

if get(handles.radiobutton_vel,'Value')==1
    h.SW = DATA;
    h.VAR_S = VAR;
else
    h.ATT = DATA;
    h.VAR_A = VAR;
end

setappdata(handles.fig_bh_cont, 'h', h)
update_fig(handles)

function update_fig(handles)
%h = getappdata(handles.fig_bh_cont, 'h');
if get(handles.radiobutton_vel,'Value')==1
    update_fig_vitesse(handles)
elseif get(handles.radiobutton_att,'Value')==1
    update_fig_att(handles)
else
    update_fig_res(handles)
end

function update_fig_vitesse(handles)
h = getappdata(handles.fig_bh_cont, 'h');
if h.change_plot
    str = getappdata(handles.fig_bh_cont, 'str');
    axes(handles.axes1)
	if get(handles.checkbox_show_xi,'Value')==0
		h.h1 = imagesc(h.xx,h.zz,1./h.SW);
	else
		h.h1 = imagesc(h.xx,h.zz,h.XI);
	end
    %caxis(handles.axes1,[0 0.3]);
    colorbar('peer',handles.axes1);
    hold(handles.axes1,'on')
    plot(handles.axes1,h.aa,h.bb,'Color',[0.5 0.5 0.5])
    xlabel(str.s119)
    ylabel(str.s120)
    set(handles.axes1,'YDir','normal')
    hold(handles.axes1,'off')
    h.change_plot = false;
else
	if get(handles.checkbox_show_xi,'Value')==0
		set(h.h1,'CData',1./h.SW)
	else
		set(h.h1,'CData',h.XI)
	end
end
setappdata(handles.fig_bh_cont, 'h', h)



function update_fig_att(handles)
h = getappdata(handles.fig_bh_cont, 'h');
if h.change_plot
    str = getappdata(handles.fig_bh_cont, 'str');
    axes(handles.axes1)
    h.h1 = imagesc(h.xx,h.zz,h.ATT);
    %caxis(handles.axes1,[0 1]);
    colorbar('peer',handles.axes1);
    hold(handles.axes1,'on')
    plot(handles.axes1,h.aa,h.bb,'Color',[0.5 0.5 0.5])
    xlabel(str.s119)
    ylabel(str.s120)
    set(handles.axes1,'YDir','normal')
    hold(handles.axes1,'off')
    h.change_plot = false;
else
    set(h.h1,'CData',h.ATT)
end
setappdata(handles.fig_bh_cont, 'h', h)


function update_fig_res(handles)
h = getappdata(handles.fig_bh_cont, 'h');
if h.change_plot
    str = getappdata(handles.fig_bh_cont, 'str');
    axes(handles.axes1)
    h.h1 = imagesc(h.xx,h.zz,h.RES);
    caxis(handles.axes1,[0 1]);
%    colorbar('peer',handles.axes1);
    hold(handles.axes1,'on')
    plot(handles.axes1,h.aa,h.bb,'Color',[0.5 0.5 0.5])
    xlabel(str.s119)
    ylabel(str.s120)
    set(handles.axes1,'YDir','normal')
    hold(handles.axes1,'off')
    h.change_plot = false;
else
    set(h.h1,'CData',h.RES)
end
setappdata(handles.fig_bh_cont, 'h', h)




function edit_vitesse(handles)
h = getappdata(handles.fig_bh_cont, 'h');
axes(handles.axes1);
[x,z,b] = ginput(1);
get(handles.pushbutton_edit,'Value')
while b==1
    ix=findnear(x,h.gridx);
    iz=findnear(z,h.gridz);
    h.vitesse(iz,ix) = h.n_vitesse;
    setappdata(handles.fig_bh_cont, 'h', h)
    update_fig(handles);
    [x,z,b] = ginput(1);
end

function edit_SW(handles)
h = getappdata(handles.fig_bh_cont, 'h');
axes(handles.axes1);
[x,z,b] = ginput(1);
get(handles.pushbutton_edit,'Value')
while b==1
    ix=findnear(x,h.xx);
    iz=findnear(z,h.zz);
    if get(handles.checkbox_show_xi,'Value') == 0   %%%YH
        h.SW(iz,ix) = 1/h.n_vitesse;
        h.VAR_S(iz,ix) = h.variance_s;
    else
        h.XI(iz,ix) = h.n_vitesse;  %%%YH 
        h.VAR_xi(iz,ix) = h.variance_s;  %%%YH
    end
    setappdata(handles.fig_bh_cont, 'h', h)
    update_fig(handles);
    [x,z,b] = ginput(1);
end

function edit_ATT(handles)
h = getappdata(handles.fig_bh_cont, 'h');
axes(handles.axes1);
[x,z,b] = ginput(1);
get(handles.pushbutton_edit,'Value')
while b==1
    ix=findnear(x,h.xx);
    iz=findnear(z,h.zz);
    h.ATT(iz,ix) = h.n_vitesse;
    h.VAR_A(iz,ix) = h.variance_a;
    setappdata(handles.fig_bh_cont, 'h', h)
    update_fig(handles);
    [x,z,b] = ginput(1);
end

function edit_RES(handles)
h = getappdata(handles.fig_bh_cont, 'h');
axes(handles.axes1);
[x,z,b] = ginput(1);
get(handles.pushbutton_edit,'Value')
while b==1
    ix=findnear(x,h.xx);
    iz=findnear(z,h.zz);
    if h.RES(iz,ix) == 0
        h.RES(iz,ix) = 1;
    else
        h.RES(iz,ix) = 0;
    end
    setappdata(handles.fig_bh_cont, 'h', h)
    update_fig(handles);
    [x,z,b] = ginput(1);
end

function cont = prepare_cont(handles)
h = getappdata(handles.fig_bh_cont, 'h');

ind = find( ~isnan(h.SW) );
slown = h.SW(ind);
ZZ = h.ZZ(ind);
XX = h.XX(ind);
var = h.VAR_S(ind);
cont.slowness.data = [ZZ XX slown var]; 
cont.slowness.variance = h.variance_s;

ind = find( ~isnan(h.XI) );
if ~isempty(ind)
    slown = h.XI(ind);
    ZZ = h.ZZ(ind);
    XX = h.XX(ind);
    var = h.VAR_xi(ind);
    cont.slowness.data_xi = [ZZ XX slown var];
end

ind = find( ~isnan(h.ATT) );
att = h.ATT(ind);
ZZ = h.ZZ(ind);
XX = h.XX(ind);
var = h.VAR_A(ind);
cont.attenuation.data = [ZZ XX att var];
cont.attenuation.variance = h.variance_a;

cont.ind_reservoir = logical(h.RES);

function pushbutton_annuler_Callback(hObject, eventdata, handles)
h = getappdata(handles.fig_bh_cont, 'h');
handles.second_output = h.cont_orig;
guidata(hObject, handles);
uiresume(handles.fig_bh_cont);


function radiobutton_vel_Callback(hObject, eventdata, handles)
if get(hObject,'Value')==1
    h = getappdata(handles.fig_bh_cont, 'h');
    str = getappdata(handles.fig_bh_cont, 'str');
    set(handles.text_valeur,'String',[str.s121,' [m/ns]'])
    set(handles.edit_valeur,'String',num2str(h.n_vitesse))
    set(handles.edit_v_inf,'String',num2str(h.v_couche_inf))
    set(handles.edit_variance_cont,'String',num2str(h.variance_s))
    set(handles.uipanel_aniso,'Visible','on');   %%%YH
    set(handles.text_cmin,'Visible','on')
    set(handles.edit_cmin,'Visible','on')
    set(handles.text_cmax,'Visible','on')
    set(handles.edit_cmax,'Visible','on')
    set(handles.text_valeur,'Visible','on')
    set(handles.edit_valeur,'Visible','on')
    set(handles.uipanel_cont_surf,'Visible','on')
    set(handles.uipanel_variance_cont,'Visible','on')
    set(handles.pushbutton_save,'Visible','on')
    h.change_plot = true;
    setappdata(handles.fig_bh_cont, 'h', h)
end
update_fig(handles)

function radiobutton_att_Callback(hObject, eventdata, handles)
if get(hObject,'Value')==1
    h = getappdata(handles.fig_bh_cont, 'h');
    str = getappdata(handles.fig_bh_cont, 'str');
    set(handles.text_valeur,'String',[str.s177,' [Np/m]'])
    set(handles.edit_valeur,'String',num2str(h.n_att))
    set(handles.edit_v_inf,'String',num2str(h.a_couche_inf))
    set(handles.edit_variance_cont,'String',num2str(h.variance_a))
    set(handles.uipanel_aniso,'Visible','off');   %%%YH
    set(handles.text_cmin,'Visible','on')
    set(handles.edit_cmin,'Visible','on')
    set(handles.text_cmax,'Visible','on')
    set(handles.edit_cmax,'Visible','on')
    set(handles.text_valeur,'Visible','on')
    set(handles.edit_valeur,'Visible','on')
    set(handles.uipanel_cont_surf,'Visible','on')
    set(handles.uipanel_variance_cont,'Visible','on')
    set(handles.pushbutton_save,'Visible','on')
    h.change_plot = true;
    setappdata(handles.fig_bh_cont, 'h', h)
end
update_fig(handles)

function radiobutton_res_Callback(hObject, eventdata, handles)
if get(hObject,'Value')==1
    h = getappdata(handles.fig_bh_cont, 'h');
    set(handles.text_cmin,'Visible','off')
    set(handles.edit_cmin,'Visible','off')
    set(handles.text_cmax,'Visible','off')
    set(handles.edit_cmax,'Visible','off')
    set(handles.text_valeur,'Visible','off')
    set(handles.edit_valeur,'Visible','off')
    set(handles.uipanel_cont_surf,'Visible','off')
    set(handles.uipanel_variance_cont,'Visible','off')
    set(handles.pushbutton_save,'Visible','off')
    set(handles.uipanel_aniso,'Visible','off');
    h.change_plot = true;
    setappdata(handles.fig_bh_cont, 'h', h)
end
update_fig(handles)


function pushbutton_importer_Callback(hObject, eventdata, handles)
str = getappdata(handles.fig_bh_cont, 'str');
[file, rep, index] = uigetfile('*.con',str.s252);
if file==0 || index==0
    return
end
h = getappdata(handles.fig_bh_cont, 'h');
cont = load([rep,file]);
if get(handles.radiobutton_vel,'Value')==1
    for n=1:size(cont,1)
        ix = findnear(cont(n,2), h.xx);
        iz = findnear(cont(n,1), h.zz);
        h.SW(iz,ix) = 1/cont(n,3);
        if size(cont,2)==4
            h.VAR_S(iz,ix) = cont(n,4);
        else
            h.VAR_S(iz,ix) = 0;
        end
    end
else
    for n=1:size(cont,1)
        ix = findnear(cont(n,2), h.xx);
        iz = findnear(cont(n,1), h.zz);
        h.ATT(iz,ix) = cont(n,3);
        if size(cont,2)==4
            h.VAR_A(iz,ix) = cont(n,4);
        else
            h.VAR_A(iz,ix) = 0;
        end
    end
end
h.change_plot = true;
setappdata(handles.fig_bh_cont, 'h', h)

update_fig(handles)


function set_str_locale(handles)
str = getappdata(handles.fig_bh_cont, 'str');
h = getappdata(handles.fig_bh_cont, 'h');

set(handles.text_valeur,'String',[str.s121,' [m/ns]'])
set(handles.edit_valeur,'String',num2str(h.n_vitesse))
set(handles.pushbutton_edit,'String',str.s122)
set(handles.pushbutton_save,'String',str.s29)
set(handles.pushbutton_quit,'String',str.s193)
set(handles.pushbutton_annuler,'String',str.s91)
set(handles.pushbutton_importer,'String',[str.s215,' ...'])
set(handles.uipanel_cont_surf,'Title',str.s212)
set(handles.uibuttongroup1,'Title',str.s222)
set(handles.checkbox_contSurf,'String',str.s213)
set(handles.checkbox_c_infer,'String',str.s214)
set(handles.text_c_infer,'String',str.s219)
set(handles.text_nf,'String',str.s220)
set(handles.text_no_f,'String',str.s221)
set(handles.radiobutton_vel,'String',str.s121)
set(handles.radiobutton_att,'String',str.s177)
%%%%YH
set(handles.radiobutton_vel,'String',str.s299)
set(handles.pushbutton_var_cont,'String',str.s302)
set(handles.text_variance_cont,'String',str.s303)
set(handles.uipanel_aniso,'Title',str.s304)
set(handles.pushbutton_import_sx,'String',str.s305)
set(handles.pushbutton_import_xi,'String',str.s306)
set(handles.checkbox_show_xi,'String',str.s307)
%%%%%%%%%%%%%%%%%%%%%%

function pushbutton_var_cont_Callback(hObject, eventdata, handles)
h = getappdata(handles.fig_bh_cont, 'h');
str = getappdata(handles.fig_bh_cont, 'str');
if get(handles.radiobutton_vel,'Value')==1
    variance = h.variance_s;
    VAR = h.VAR_S;
else
    variance = h.variance_a;
    VAR = h.VAR_A;
end
axes(handles.axes1)
h.h1 = imagesc(h.xx,h.zz,VAR);
%caxis(handles.axes1,[-variance variance]);
colorbar('peer',handles.axes1);
hold(handles.axes1,'on')
plot(handles.axes1,h.aa,h.bb,'Color',[0.5 0.5 0.5])
xlabel(str.s119)
ylabel(str.s120)
set(handles.axes1,'YDir','normal')
hold(handles.axes1,'off')

[x,z,b] = ginput(1);
while b==1
    ix=findnear(x,h.xx);
    iz=findnear(z,h.zz);
    if VAR(iz,ix) == 0
        VAR(iz,ix) = variance;
    else
        VAR(iz,ix) = 0;
    end
    set(h.h1,'CData',VAR)
    [x,z,b] = ginput(1);
end
if get(handles.radiobutton_vel,'Value')==1
    h.VAR_S = VAR;
else
    h.VAR_A = VAR;
end

h.change_plot = true;
setappdata(handles.fig_bh_cont, 'h', h)

update_fig(handles)

function edit_variance_cont_Callback(hObject, eventdata, handles)
h = getappdata(handles.fig_bh_cont, 'h');
if get(handles.radiobutton_vel,'Value')==1
    h.variance_s = str2double(get(hObject,'String'));
else
    h.variance_a = str2double(get(hObject,'String'));
end
setappdata(handles.fig_bh_cont, 'h', h)


function edit_variance_cont_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_cmin_Callback(hObject, eventdata, handles)
cmin = str2double(get(handles.edit_cmin,'String'));  %%YH
cmax = str2double(get(handles.edit_cmax,'String'));
if cmax<cmin
    cmax = cmin+0.01;
    set(handles.edit_cmax, 'String', num2str(cmax))
end
caxis(handles.axes1,[cmin cmax]);
colorbar('peer',handles.axes1);


function edit_cmin_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_cmax_Callback(hObject, eventdata, handles)
cmax = str2double(get(handles.edit_cmax,'String'));   %%YH
cmin = str2double(get(handles.edit_cmin,'String'));
if cmin>cmax
    cmin = cmax-0.01;
    set(handles.edit_cmin, 'String', num2str(cmin))
end
caxis(handles.axes1,[cmin cmax]);
colorbar('peer',handles.axes1);


function edit_cmax_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function pushbutton_import_sx_Callback(hObject, eventdata, handles)
if get(handles.radiobutton_att,'Value')==1
    errordlg('Elliptic anisotropy not defined for attenuation')
    return
end
[filename, pathname] = uigetfile({'*.dat','x-y-z-s_x-[var] data file (*.dat)';...
    '*.*',  'All Files (*.*)'}, 'Pick a file');
if isequal(filename,0) || isequal(pathname,0)
    return
else
    data = load([pathname,filename]);
end
if size(data,2)~=4 && size(data,2)~=5
    errordlg('File must contain x y z v_x, and optionally variance of slowness')
    return
end
h = getappdata(handles.fig_bh_cont, 'h');
if isempty(h.plan)
    errordlg('Grid plane not defined')
    return
end
coord = proj_plan(data(:,1:3), h.plan.x0, h.plan.a);
coord = transl_rotat(coord, h.plan.origine, h.plan.az, h.plan.dip);

for n=1:size(data,1)
    ix = findnear(coord(n,1), h.xx);
    iz = findnear(coord(n,3), h.zz);
    h.SW(iz,ix) = data(n,4);
    if size(data,2)==5
        h.VAR_S(iz,ix) = data(n,5);
    else
        h.VAR_S(iz,ix) = 0;
    end
end
h.change_plot = true;
setappdata(handles.fig_bh_cont, 'h', h)

update_fig_vitesse(handles)



function pushbutton_import_xi_Callback(hObject, eventdata, handles)
if get(handles.radiobutton_att,'Value')==1
    errordlg('Elliptic anisotropy not defined for attenuation')
    return
end
[filename, pathname] = uigetfile({'*.dat','x-y-z-s_x-[var] data file (*.dat)';...
    '*.*',  'All Files (*.*)'}, 'Pick a file');
if isequal(filename,0) || isequal(pathname,0)
    return
else
    data = load([pathname,filename]);
end
if size(data,2)~=4 && size(data,2)~=5
    errordlg('File must contain x y z s_x, and optionally variance of slowness')
    return
end
h = getappdata(handles.fig_bh_cont, 'h');
if isempty(h.plan)
    errordlg('Grid plane not defined')
    return
end
coord = proj_plan(data(:,1:3), h.plan.x0, h.plan.a);
coord = transl_rotat(coord, h.plan.origine, h.plan.az, h.plan.dip);

for n=1:size(data,1)
    ix = findnear(coord(n,1), h.xx);
    iz = findnear(coord(n,3), h.zz);
    h.XI(iz,ix) = data(n,4);
    if size(data,2)==5
        h.VAR_xi(iz,ix) = data(n,5);
    else
        h.VAR_xi(iz,ix) = 0;
    end
end
h.change_plot = true;
setappdata(handles.fig_bh_cont, 'h', h)

update_fig_vitesse(handles)

function checkbox_show_xi_Callback(hObject, eventdata, handles)
h = getappdata(handles.fig_bh_cont, 'h');
h.change_plot = true;
setappdata(handles.fig_bh_cont, 'h', h)
update_fig(handles)
edit_cmax_Callback(hObject, eventdata, handles);  %%YH
edit_cmin_Callback(hObject, eventdata, handles);  %%YH

function pushbutton_reinit_Callback(hObject, eventdata, handles)
h = getappdata(handles.fig_bh_cont, 'h');
if get(handles.radiobutton_vel,'Value')==1
	h.SW(:) = nan;
elseif get(handles.radiobutton_att,'Value')==1
    h.ATT(:) = nan;
else
    h.RES(:) = 0;
end
h.change_plot = true;
setappdata(handles.fig_bh_cont, 'h', h)
set(handles.checkbox_contSurf,'Value',0);  %%YH
set(handles.checkbox_c_infer,'Value',0);  %%YH
update_fig(handles)  

function fig_bh_cont_CloseRequestFcn(hObject, eventdata, handles)
handles.second_output = prepare_cont(handles);
guidata(hObject, handles);
uiresume(handles.fig_bh_cont);
%delete(hObject);
