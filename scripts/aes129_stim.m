% Create wave files for a linear array

% The data of the corresponding experiment is located here:
% https://www.qu.t-labs.tu-berlin.de/audio/experiments/2010-01_AES128_focused_sources
%
% The HRIR dataset measured with FABIAN is located here:
% https://www.qu.t-labs.tu-berlin.de/audio/measurements/HRIRs/FABIAN_anechoic
%
% The headphone compensation can be found here:
% https://www.qu.t-labs.tu-berlin.de/audio/measurements/headphone_compensation_filters/FABIAN_AKG_K601
%

% AUTHOR: Hagen Wierstorf


%% ===== Variables ======================================================

clear all;

% Geometry of the test
%
%    x-axis                      [X0 Y0]
%       <------^--^--^--^--^--^--^--^--^--^--^--^--^--^--^-------
%                                   |
%                                   x [xs ys] (Focused source)
%                                 | |
%                               |   |
%                             |     |
%                           | alpha |
%                         | R       |
%                       |           |
%                     O             |
%                  [X,Y]            |
%                                   v y-axis
%
% Angle of listener position (Note: if no angle is given, only the
% reference wave file using a single source is created, otherwise also wave
% files for focused sources located at the given direction are created
alpha = [0 -30 -60];
% Array length
%L = [4 2 1 0.5];
%R = 1;
L = [10 2 1 0.5];
R = 4;
% Aliasing frequency for the given position
%fal = [5000 4100 2200];     % L = 4, R = 1;
fal = [3700 2100 1500];     % L = 10; R = 4;
%fal = [1500 1500 1500];
% Focused source position
xs = 0;
ys = 1;
% Content to produce (castanets, speech, cello)
content = 'castanets';
% Directory to store the wave files
%outdir = ['D:/data/experiments/2010-01_AES128_focused_sources/'...
%          'stimuli/enhanced/'];
outdir = '~/data/experiments/2010-09_AES129_focused_sources/stimuli/sascha/';

%% ===== Configuration ==================================================

% Explicit configuration to ensure reproducibility
% === General audio ===
% Samplingrate (Hz)
conf.fs = 44100;
% Speed of sound (m/s)
conf.c = 343;


% === Headphone ===
% Headphone compensation (true or false)
conf.usehcomp = true;
% Headphone compensation file for left and right ear.
conf.hcomplfile = ...
    ['~/data/measurements/headphone_compensation_filters/'...
     'FABIAN_AKG_K601/'...
     'FABIAN_AKG_K601_(left)_4096_min_phase_marg100_inverse.wav'];
conf.hcomprfile = ...
    ['~/data/measurements/headphone_compensation_filters/'...
     'FABIAN_AKG_K601/'...
     'FABIAN_AKG_K601_(right)_4096_min_phase_marg100_inverse.wav'];


% === WFS ===
% Loudspeaker distance (m)
conf.dx0 = 0.15;
% Array position (m)
conf.X0 = 0;
conf.Y0 = 0;
% Listener direction offset (defines the 0� direction of the listener,
% default: 0� == negative y-direction)
conf.listoffset = 0;
% WFS preequalization-filter (true or false)
conf.usehpre = true;
% Lower frequency limit of preequalization filter (= frequency when
% subwoofer is active) (Hz)
conf.hpreflow = 25;
% Upper frequency limit of preequalization filter (= aliasing frequency of
% system) (Hz)
%conf.hprefhigh = 2500; This is set below!
% Use tapering window
conf.usetapwin = true;
% Size of the tapering window (% of array length => 0..1)
conf.tapwinlen = 0.3;


% === Virtual Source ===
% Pre-delay for causality for focused sources (s)
% Note: for a non focused point source this will be set automaticly to 0
% from wfs_brs!
conf.t0 = -3*1024/conf.fs;


% === HRIR ===
% HRIR dataset
conf.irsfile = '/home/hagen/data/ir_databases/FABIAN_RAR.mat';


% === BRIR ===
% Target length of BRIR impulse responses
conf.N = 2^14;
% Angles for the BRS set for the SSR (first two columns of the BRIR are 0�
% of the listener direction, next two columns are 1�, etc. So the
% brsangles has to spin around the other direction, because the source
% moves in opposite direction to the listener direction; see wfs_brs_set)
conf.brsangles = 360:-1:1;
% Auralisation files
conf.speechfile = '~/data/signals/speech.wav';
conf.cellofile = '~/data/signals/cello.wav';
conf.castanetsfile = '~/data/signals/castanets.wav';


% === Plotting ===
% Plot the results etc.
conf.useplot = false;
% Use gnuplot
conf.usegnuplot = false;




%% ===== Computation ====================================================

% Read HRIRs
hrirs = read_irs(conf);

% Compute BRIRs
for ll = 1:length(L)
    for r = 1:length(R)

        % Compute BRIR for reference single source
        brir = ref_brs(0,R(r)+1,conf.listoffset,xs,ys,hrirs,conf);
        % Auralize BRIR
        outsig = auralize_brs(brir,content);

        % Write file
        outfile = sprintf('%sref_xs%d_ys%d_R%d_phi%d_%s.wav',outdir,xs,ys,...
                          R(r),0,content);
        wavwrite(outsig,conf.fs,16,outfile);


        for a = 1:length(alpha)

            % Calculate listener positions (X,Y)
            X = R(r) * sin(-alpha(a)/180*pi) + xs;
            Y = sqrt(R(r)^2-(X-xs)^2) + ys;

            % Set aliasing frequency for pre-equalization filter
            conf.hprefhigh = fal(a);

            %echo_time(X,Y,xs,ys,L(ll),conf)
            %conf.usegnuplot = 1;
            %echo_direction(X,Y,alpha(a)+conf.listoffset,xs,ys,L(ll),conf);
            % Calculate BRIR
            brir = wfs_brs(X,Y,alpha(a)+conf.listoffset,xs,ys,L(ll),hrirs,conf);
            % Auralize BRIR
            outsig = auralize_brs(brir,content);

            % Write file
            outfile = sprintf('%s%.1fm_xs%d_ys%d_R%d_phi%d_%s.wav',outdir,L(ll),...
                              xs,ys,R(r),alpha(a),content);
            wavwrite(outsig,conf.fs,16,outfile);

        end
    end
end
