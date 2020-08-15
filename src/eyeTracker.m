% Eyelink already initialized!
% Running experiment on a 'EYELINK CL 4.56 ' tracker.
% Error in function Open: Usage error
% Could not find *any* audio hardware on your system - or at least not with
% the provided deviceid, if any!
% Error in function FillRect: Invalid Window (or Texture) Index provided:
% It doesn't correspond to an open window or texture.
% Did you close it accidentally via Screen('Close') or Screen('CloseAll') ?
% EYELINK: WARNING! PsychEyelinkCallRuntime() Failed to call eyelink runtime
% callback function PsychEyelinkDispatchCallback [rc = 1]!
% EYELINK: WARNING! Make sure that function is on your Matlab/Octave path and
% properly initialized.
% EYELINK: WARNING! May also be an error during execution of that function.
% Type ple at command prompt for error messages.
% EYELINK: WARNING! Auto-Disabling all callbacks to the runtime environment
% for safety reasons.
% Eyelink: In PsychEyelink_get_input_key(): Error condition detected: Trying
% to send TERMINATE_KEY abort keycode!
% Eyelink: In PsychEyelink_get_input_key(): Error condition detected: Trying
% to send TERMINATE_KEY abort keycode!
% Error in function FillRect: Invalid Window (or Texture) Index provided:
% It doesn't correspond to an open window or texture.
% Did you close it accidentally via Screen('Close') or Screen('CloseAll') ?
% Error using Screen
% Usage:
%
% Screen('FillRect', windowPtr [,color] [,rect] )
%
% Error in eyeTracker (line 150)
% Screen('FillRect', cfg.screen.win, [0 0 0]);
%
% Error in visualLocTanslational (line 52)
% [el] = eyeTracker('Calibration', cfg);


function [el, edfFile] = eyeTracker(input, cfg, varargin)
    % [el, edfFile] = eyeTracker(input, cfg, varargin)
    %
    % Mosto of the comments with explanation (e.g. 'STEP #') come from `EyelinkEventExample.m`
    %
    % Optional useful functions to implement in future:
    %
    %  - Set level of verbosity for error/warning/status messages. ‘level’ optional, new
    %    level of verbosity. ‘oldlevel’ is the old level of verbosity. The following
    %    levels are supported: 0 = Shut up. 1 = Print errors, 2 = Print also warnings, 3
    %    = Print also some info, 4 = Print more useful info (default), >5 = Be very
    %    verbose (mostly for debugging the driver itself).
    %
    %   oldlevel = Eyelink(‘Verbosity’ [,level]);
    %
    %  - Tag the ET data outout
    %
    %   Eyelink('command', 'add_file_preamble_text', 'Recorded by EyelinkToolbox demo-experiment');
    %
    %  - Set parser (conservative saccade thresholds)
    %
    %   Eyelink('command', 'saccade_velocity_threshold = 35');
    %   Eyelink('command', 'saccade_acceleration_threshold = 9500');
    %
    %  - Drift correction
    %
    %   EyelinkDoDriftCorrection(el);
    %
    %   success = EyelinkDoDriftCorrection(el);
    %   if success~=1
    %      Eyelink('shutdown');
    %      cleanUp()
    %      return;
    %   end
    %
    %  - Tag the recording, in the past caused delays during the presentation so I avoided to use it
    %
    %   Eyelink('message', 'Trial 1');



    if ~cfg.eyeTracker.do

        el = [];

    else

        switch input

            case 'Calibration'

                %% STEP 2
                % Provide Eyelink with details about the graphics environment
                %  and perform some initializations. The information is returned
                %  in a structure that also contains useful defaults
                %  and control codes (e.g. tracker state bit and Eyelink key values).
                el = EyelinkInitDefaults(cfg.screen.win);

                % Calibration has silver background with black targets, sound and smaller
                %  targets
                el.backgroundcolour        = [192 192 192, (cfg.screen.win)];
                el.msgfontcolour           = BlackIndex(cfg.screen.win);
                el.calibrationtargetcolour = BlackIndex(cfg.screen.win);
                el.calibrationtargetsize   = 1;
                el.calibrationtargetwidth  = 0.5;
                el.displayCalResults       = 1;

                % Call this function for changes to the calibration structure to take
                %  affect
                EyelinkUpdateDefaults(el);

                %% STEP 3
                % Initialization of the connection with the Eyelink Gazetracker.
                %  exit program if this fails.

                % Initialize EL and make sure it worked: returns: 0 if OK, -1 if error
                ELinit  = Eyelink('Initialize');
                if ELinit ~= 0
                    fprintf('Eyelink is not initialized, aborted.\n');
                    Eyelink('Shutdown');
                    CleanUp()
                end

                % Make sure EL is still connected: returns 1 if connected, -1 if dummy-connected,
                %  2 if broadcast-connected and 0 if not connected
                ELconnection = Eyelink('IsConnected');
                if ELconnection ~= 1
                    fprintf('Eyelink is not connected, aborted.\n');
                    Eyelink('Shutdown');
                    CleanUp()
                end

                % Last check that the EL is up to work
                if ~EyelinkInit(0, 1)
                    fprintf('Eyelink Init aborted.\n');
                    CleanUp()
                end

                % Open the edf file to write the data
                edfFile = 'demo.edf';
                Eyelink('Openfile', edfFile);

                [el.v, el.vs] = Eyelink('GetTrackerVersion');
                fprintf('Running experiment on a ''%s'' tracker.\n', el.vs);

                % Make sure that we get gaze data from the Eyelink
                Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');

                %% STEP 4
                % Setting the proper recording resolution, proper calibration type,
                %   as well as the data file content;

                % This command is crucial to map the gaze positions from the tracker to
                %  screen pixel positions to determine fixation
                Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, 0, 0);
                Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, 0, 0);

                % Set calibration type.
                Eyelink('command', 'calibration_type = HV5');

                if cfg.eyeTracker.defaultCalibration

                    % Set default calibration parameters
                    Eyelink('command', 'generate_default_targets = YES');

                else

                    % Set default calibration parameters
                    Eyelink('command', 'generate_default_targets = NO');

                    % Calibration target locations, set manually the dots
                    %  coordinates, here for 6 dots

                    % [width, height]=Screen('WindowSize', screenNumber);

                    Eyelink('command','calibration_samples = 6');
                    Eyelink('command','calibration_sequence = 0,1,2,3,4,5');
                    Eyelink('command','calibration_targets = %d,%d %d,%d %d,%d %d,%d %d,%d',...
                        640,512, ... %width/2,height/2
                        640,102, ... %width/2,height*0.1
                        640,614, ... %width/2,height*0.6
                        128,341, ... %width*0.1,height*1/3
                        1152,341 );  %width-width*0.1,height*1/3

                    % Validation target locations
                    Eyelink('command','validation_samples = 5');
                    Eyelink('command','validation_sequence = 0,1,2,3,4,5');
                    Eyelink('command','validation_targets = %d,%d %d,%d %d,%d %d,%d %d,%d',...
                        640,512, ... %width/2,height/2
                        640,102, ... %width/2,height*0.1
                        640,614, ... %width/2,height*0.6
                        128,341, ... %width*0.1,height*1/3
                        1152,341 );  %width-width*0.1,height*1/3

                end

                % Set EDF file contents (not clear what this lines are used for)
                el.vsn = regexp(el.vs, '\d', 'match'); % wont work on EL

                % Enter Eyetracker camera setup mode, calibration and validation
                EyelinkDoTrackerSetup(el);

                % Go back to default screen background color
                Screen('FillRect', cfg.screen.win, cfg.color.background);
                Screen('Flip', cfg.screen.win);

            case 'StartRecording'

                % STEP 5
                % EyeLink Start recording the block
                Eyelink('Command', 'set_idle_mode');
                WaitSecs(0.05);
                Eyelink('StartRecording');

                % Check recording status, stop display if error
                checkrec = Eyelink('checkrecording');
                if checkrec ~= 0
                    fprintf('\nEyelink is not recording.\n\n');
                    Eyelink('Shutdown');
                    Screen('CloseAll');
                    return
                end

                % Record a few samples before we actually start displaying
                %  otherwise you may lose a few msec of data
                WaitSecs(0.1);

                % Mark the beginning of the trial, here start the stimulation of the experiment
                Eyelink('Message', 'SYNCTIME');

            case 'StopRecordings'

                % STEP 8
                % Finish up: stop recording of eye-movements

                % EyeLink Stop recording the block
                Eyelink('Message', 'BLANK_SCREEN');

                % Add 100 msec of data to catch final events
                WaitSecs(0.1);

                % Stop recoding
                Eyelink('StopRecording');

            case 'Shutdown'

                % STEP 6
                % At the end of the experiment, save the edf file and shut down connection
                %  with Eyelink

                # Set the edf file path + name
                edfFileName = fullfile( ...
                    cfg.dir.outputSubject, ...
                    'eyetracker', ...
                    cfg.fileName.eyetracker);

                Eyelink('Command', 'set_idle_mode');

                WaitSecs(0.5);

                Eyelink('CloseFile');

                % Download data file
                try
                    fprintf('Receiving data file ''%s''\n', edfFileName);

                    % Download the file and check the status: returns file size if OK, 0 if file
                    %  transfer was cancelled, negative = error
                    elReceiveFile = Eyelink('ReceiveFile', '', edfFileName);

                    if elReceiveFile > 0
                        fprintf('Downloading eye tracker file of size %d\n', elReceiveFile);
                    end

                    if exist(edfFileName, 'file') == 2

                        fprintf('Data file ''%s'' can be found in ''%s''\n', ...
                            cfg.fileName.eyetracker, ...
                            fullfile(cfg.dir.outputSubject, 'eyetracker'));

                    end

                catch

                    fprintf('Problem receiving eye tracker data ''%s''\n', edfFileName);

                end

                % Close connection with EyeLink
                Eyelink('shutdown');

        end

    end

end

%% subfunctions for iView

% function ivx = eyeTrackInit(cfg)
%     % initialize iView eye tracker
%
%     ivx = [];
%
%     if cfg.eyeTracker
%
%         host = cfg.eyetracker.Host;
%         port = cfg.eyetracker.Port;
%         window = cfg.eyetracker.Window;
%
%         % original: ivx=iviewxinitdefaults(window, 9 , host, port);
%         ivx = iviewxinitdefaults2(window, 9, [], host, port);
%         ivx.backgroundColour = 0;
%         [~, ivx] = iViewX('openconnection', ivx);
%         [success, ivx] = iViewX('checkconnection', ivx);
%         if success ~= 1
%             error('connection to eye tracker failed');
%         end
%     end
% end
%
% function eyeTrackStart(ivx, cfg)
%     % start iView eye tracker
%     if cfg.eyeTracker
%         % to clear data buffer
%         iViewX('clearbuffer', ivx);
%         % start recording
%         iViewX('startrecording', ivx);
%         iViewX('message', ivx, ...
%             [ ...
%             'Start_Ret_', ...
%             'Subj_', cfg.Subj, '_', ...
%             'Run', num2str(cfg.Session(end)),  '_', ...
%             cfg.Apperture, '_', ...
%             cfg.Direction]);
%         iViewX('incrementsetnumber', ivx, 0);
%     end
% end
%
% function eyeTrackStop(ivx, cfg)
%     % stop iView eye tracker
%
%     if cfg.eyeTracker
%
%         % stop tracker
%         iViewX('stoprecording', ivx);
%
%         % save data file
%         thedatestr = datestr(now, 'yyyy-mm-dd_HH.MM');
%         strFile = fullfile(OutputDir, ...
%             [cfg.Subj, ...
%             '_run', num2str(cfg.Session(end)), '_', ...
%             cfg.Apperture, '_', ...
%             cfg.Direction, '_', ...
%             thedatestr, '.idf"']);
%         iViewX('datafile', ivx, strFile);
%
%         % close iView connection
%         iViewX('closeconnection', ivx);
%     end
% end
