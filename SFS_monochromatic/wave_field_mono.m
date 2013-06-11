function [P,x,y,z] = wave_field_mono(X,Y,Z,x0,src,D,f,conf)
%WAVE_FIELD_MONO simulates a monofrequent wave field for the given driving
%signals and secondary sources
%
%   Usage: [P,x,y,z] = wave_field_mono(X,Y,Z,x0,src,D,f,[conf])
%
%   Input parameters:
%       X           - [xmin,xmax]
%       Y           - [ymin,ymax]
%       Z           - [zmin zmax]
%       x0          - secondary sources [n x 6]
%       src         - source model for the secondary sources. This describes the
%                     Green's function, that is used for the modeling of the
%                     sound propagation. Valid models are:
%                       'ps' - point source
%                       'ls' - line source
%                       'pw' - plane wave
%       D           - driving signals for the secondary sources [m x n]
%       f           - monochromatic frequency (Hz)
%       conf        - optional configuration struct (see SFS_config)
%
%   Output parameters:
%       P           - Simulated wave field
%       x           - corresponding x axis
%       y           - corresponding y axis
%       z           - corresponding z axis
%
%   WAVE_FIELD_MONO(X,Y,Z,x0,src,D,f,conf) simulates a wave field
%   for the given secondary sources, driven by the corresponding driving
%   signals. The given source model src is applied by the corresponding Green's
%   function for the secondary sources. The simulation is done for one
%   frequency in the frequency domain, by calculating the integral for P with a
%   summation.
%   
%   To plot the result use plot_wavefield(P,x,y,z).
%
%   References:
%       
%       Williams1999 - Fourier Acoustics (Academic Press)
%
%   see also: plot_wavefield, wave_field_mono_wfs_25d

%*****************************************************************************
% Copyright (c) 2010-2013 Quality & Usability Lab, together with             *
%                         Assessment of IP-based Applications                *
%                         Deutsche Telekom Laboratories, TU Berlin           *
%                         Ernst-Reuter-Platz 7, 10587 Berlin, Germany        *
%                                                                            *
% Copyright (c) 2013      Institut fuer Nachrichtentechnik                   *
%                         Universitaet Rostock                               *
%                         Richard-Wagner-Strasse 31, 18119 Rostock           *
%                                                                            *
% This file is part of the Sound Field Synthesis-Toolbox (SFS).              *
%                                                                            *
% The SFS is free software:  you can redistribute it and/or modify it  under *
% the terms of the  GNU  General  Public  License  as published by the  Free *
% Software Foundation, either version 3 of the License,  or (at your option) *
% any later version.                                                         *
%                                                                            *
% The SFS is distributed in the hope that it will be useful, but WITHOUT ANY *
% WARRANTY;  without even the implied warranty of MERCHANTABILITY or FITNESS *
% FOR A PARTICULAR PURPOSE.                                                  *
% See the GNU General Public License for more details.                       *
%                                                                            *
% You should  have received a copy  of the GNU General Public License  along *
% with this program.  If not, see <http://www.gnu.org/licenses/>.            *
%                                                                            *
% The SFS is a toolbox for Matlab/Octave to  simulate and  investigate sound *
% field  synthesis  methods  like  wave  field  synthesis  or  higher  order *
% ambisonics.                                                                *
%                                                                            *
% http://dev.qu.tu-berlin.de/projects/sfs-toolbox       sfstoolbox@gmail.com *
%*****************************************************************************


%% ===== Checking of input  parameters ==================================
nargmin = 7;
nargmax = 8;
narginchk(nargmin,nargmax);
isargvector(X,Y,Z,D);
isargsecondarysource(x0);
isargpositivescalar(f);
isargchar(src);
if nargin<nargmax
    conf = SFS_config;
else
    isargstruct(conf);
end
if size(x0,1)~=length(D)
    error(['%s: The number of secondary sources (%i) and driving ', ...
        'signals (%i) does not correspond.'], ...
        upper(mfilename),size(x0,1),length(D));
end


%% ===== Configuration ==================================================
% Plotting result
useplot = conf.useplot;


%% ===== Computation ====================================================
% Create a x-y-grid
[xx,yy,zz,x,y,z] = xyz_grid(X,Y,Z,conf);
% Initialize empty wave field
P = zeros(length(y),length(x));
% Integration over secondary source positions
for ii = 1:size(x0,1)

    % ====================================================================
    % Secondary source model G(x-x0,omega)
    % This is the model for the secondary sources we apply.
    % The exact function is given by the dimensionality of the problem, e.g. a
    % point source for 3D
    G = greens_function_mono(xx,yy,zz,x0(ii,1:3),src,f,conf);

    % ====================================================================
    % Integration
    %              /
    % P(x,omega) = | D(x0,omega) G(x-x0,omega) dx0
    %              /
    %
    % see: Spors2009, Williams1993 p. 36
    P = P + D(ii).*G;

end

% === Scale signal (at xref) ===
P = norm_wave_field(P,x,y,z,conf);

% ===== Plotting =========================================================
if nargout==0 || useplot
    plot_wavefield(P,x,y,z,x0,conf);
end
