function varargout = gui(varargin)
% GUI MATLAB code for gui.fig                    
%      GUI, by itself, creates a new GUI or raises the existing
%      singleton*.
%
%      H = GUI returns the handle to a new GUI or the handle to
%      the existing singleton*.
%
%      GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI.M with the given input arguments.
%
%      GUI('Property','Value',...) creates a new GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
% Edit the above text to modify the response to help gui

% Last Modified by GUIDE v2.5 05-Apr-2021 14:20:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui_OpeningFcn, ...
                   'gui_OutputFcn',  @gui_OutputFcn, ...
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

% NOTE [by Ananda, 4 April 2021]: This GUI replaces the old collectInfo()
% function. This version is more user-friendly.


% --- Executes just before gui is made visible.
function gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gui (see VARARGIN)

global strName;
if(nargin==4), strName = varargin{:};   % Is this training or assessment?
else strName = 'Result';
end

% Choose default command line output for gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Load data to initialize what user sees on the GUI
load('setting.mat');
handles.select = guiOut;

% Initialize the handles as struct (this data type is important)
my.subject = {'S01','S02','S03','S04','S05','S06','S07','S08','S09','S10',...
              'S11','S12','S13','S14','S15','S16','S17','S18','S19','S20',...
              'S21','S22','S23','S24','S25','S26','S27','S28','S29','S30'};
my.session = {'Base','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','Post','1mth'};

if ( strcmp(strName,'train') )
    my.block   = {'1','2','3','4','5','6','7','8','9','10'};
    set(handles.block, 'String', my.block);
    set(handles.block, 'Value', find(strcmp(my.block, guiOut.block),1));
    set(handles.ctrl,'visible','on');
else
    my.block   = {'1'};
    set(handles.block, 'String', my.block);
    set(handles.block, 'Value', 1);
    set(handles.ctrl,'visible','off')
end

% Assign the loaded data to be the content of the respective object
set(handles.subject, 'String', my.subject);
set(handles.subject, 'Value', find(strcmp(my.subject, guiOut.subject),1));
set(handles.session, 'String', my.session);
set(handles.session, 'Value', find(strcmp(my.session, guiOut.session),1) );
set(handles.practice, 'Value', 0);
set(handles.ctrl, 'Value', guiOut.control);

% Update handles structure
guidata(handles.figure1, handles);

% UIWAIT makes gui wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% IMPORTANT: This is how I return the output of the GUI
varargout{1} = handles.select;

% Then the figure can deleted once quit
delete(hObject); pause(0.5);



% --- Executes on selection change in subject.
function subject_Callback(hObject, eventdata, handles)
% hObject    handle to subject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns subject contents as cell array
%        contents{get(hObject,'Value')} returns selected item from subject
contents = cellstr(get(hObject,'String'));
subject  = contents{get(hObject,'Value')};

% Save the new subject ID
handles.select.subject = subject;
guidata(hObject,handles)



% --- Executes during object creation, after setting all properties.
function subject_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in session.
function session_Callback(hObject, eventdata, handles)
% hObject    handle to session (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns session contents as cell array
%        contents{get(hObject,'Value')} returns selected item from session
contents = cellstr(get(hObject,'String'));
session  = contents{get(hObject,'Value')};

% Save the new session
handles.select.session = session;
guidata(hObject,handles)



% --- Executes during object creation, after setting all properties.
function session_CreateFcn(hObject, eventdata, handles)
% hObject    handle to session (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in block.
function block_Callback(hObject, eventdata, handles)
% hObject    handle to block (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns block contents as cell array
%        contents{get(hObject,'Value')} returns selected item from block
contents = cellstr(get(hObject,'String'));
block    = contents{get(hObject,'Value')};

% Save the new block value
handles.select.block = block;
guidata(hObject,handles)



% --- Executes during object creation, after setting all properties.
function block_CreateFcn(hObject, eventdata, handles)
% hObject    handle to block (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in practice.
function practice_Callback(hObject, eventdata, handles)
% hObject    handle to practice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of practice
practice = get(hObject,'Value');

% Disable user interface when practice, no need to set anything...
if practice, status = 'Off'; else, status = 'On'; end
set(handles.subject, 'Enable', status);
set(handles.session, 'Enable', status);
set(handles.block, 'Enable', status);

% Save the new block value
handles.select.practice = practice;
guidata(hObject,handles)


% --- Executes on button press in ctrl.
function ctrl_Callback(hObject, eventdata, handles)
% hObject    handle to ctrl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ctrl
control = get(hObject,'Value');

% Save the new block value
handles.select.control = control;
guidata(hObject,handles)



% --- Executes on button press in enterButton.
function enterButton_Callback(hObject, eventdata, handles)
% hObject    handle to enterButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global strName; global myPath;
localpath = strcat(myPath,'\Trial Data\');

% Hint: get(hObject,'Value') returns toggle state of enterButton
if (get(hObject,'Value'))
    formatOut = 'HHMM';    % Extract current time
    filename = strcat(handles.select.subject,'\',handles.select.session,'\',handles.select.subject, ...
           '_',strName,'_',handles.select.session,'_',handles.select.block,'_',datestr(now,formatOut))
 
    % If the session folder doesn't exist, create one first to save the data
    if ~exist(strcat(localpath,handles.select.subject,'\',num2str(handles.select.session)), 'dir')
        fprintf('Subject folder not found. Creating one....\n\n');
        mkdir(strcat(localpath,handles.select.subject,'\',num2str(handles.select.session)))   % For session folder!
    else
        fprintf('Subject folder found or already created!\n\n');
    end
    
    if (handles.select.control), ctrl='control'; else ctrl='treatment'; end;

    if (handles.select.practice), fprintf('Giving practice with instruction first\n\n');
    else
        if (strcmp(strName,'train'))
            fprintf('Training %s, session %s, block %s as %s\n\n', handles.select.subject, ...
            handles.select.session, handles.select.block, ctrl);   % display for checking...
        else
            fprintf('Testing %s, session %s\n\n', handles.select.subject, handles.select.session);
        end
    end
        
    handles.select.practice = 0; %%%s

    % Pass the filename to handles.select struct
    handles.select.filename = filename;
    guidata(hObject,handles);    % update the handles!
     
    % Use UIRESUME instead of delete because the OutputFcn needs to get updated handles structure.
    uiresume(handles.figure1);
    
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(hObject);
else
    % The GUI is no longer waiting, just close it
    delete(hObject);
end
