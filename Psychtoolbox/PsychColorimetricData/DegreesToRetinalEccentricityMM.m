function eccMm = DegreesToRetinalEccentricityMM(eccDegrees,species,method,eyeLengthMm)
% eccMm = DegreesToRetinalEccentricityMM(eccDegrees,[species],[method],[eyeLengthMm])
%
% Convert eccentricity in degrees to retinal eccentricity in mm.   By
% default, this takes into account a simple model eye, rather than just
% relying on a linear small angle approximation.
%
% Input:
%   eccDegrees -- retinal eccentricity in degrees
%   species -- what species
%     'Human'  -- Human eye [default]
%     'Rhesus' -- Rhesus monkey
%   method -- what method
%     'DaceyPeterson'  -- formulae from Dacey & Peterson (1992) [default]
%     'Linear' -- linear, based on small angle approx
%  eyeLengthMm -- Eye length to assume for linear calculation, should be
%      the posterior nodal distance. Defaults to the default values returned
%      by function EyeLength for the chosen species.
%
% The Dacey and Peterson formulae are based on digitizing and fitting
% curves published by
%    1) Drasdo and Fowler, 1974 (British J. Opthth, 58,pp. 709 ff., Figure 2,
%    for human.
%    2) Perry and Cowey (1985, Vision Reserch, 25, pp. 1795-1810, Figure 4,
%    for rhesus monkey.
% These curves, I think, were produced by ray tracing or otherwise solving
% model eyes.  The eyeLengthMm parameter does not affect what this method
% does.
% 
% The default eye length returned by EyeLength for Human is currently the Rodiek value of
% 16.1 mm.  Drasdo and Fowler formulae are based on a length of about this, 
% so the linear and DaceyPeterson methods are roughly consistent for small
% angles.  Similarly with the Rhesus default.  Using other EyeLength's will
% make the two methods inconsistent.
%
% The Dacey and Peterson equations don't go through (0,0), but rather
% produce a visual angle of 0.1 degree for an eccentricity of 0.  This
% seems bad to me. I modified the formulae so that they use the linear
% approximation for small angles, producing a result that does go through
% (0,0).
%
% See also: EyeLength, RetinalEccentricityMMToDegrees, DegreesToRetinalMM, RetinalMMToDegrees
%
% 6/30/2015  dhb  Wrote it.

%% Set defaults
if (nargin < 2 || isempty(species))
    species = 'Human';
end
if (nargin < 3 || isempty(method))
    method = 'DaceyPeterson';
end
if (nargin < 4 || isempty(eyeLengthMm))
    switch (species)
        case 'Human'
            eyeLengthMm = EyeLength(species,'Rodieck');
        case 'Rhesus'
            eyeLengthMm = EyeLength(species,'PerryCowey');
        otherwise
            error('Unknown species specified');
    end
end

%% Checks
if (any(eccDegrees < 0))
    error('Can only convert non-negative eccentricities');
end

%% Do the method dependent thing
switch (method)
    case 'DaceyPeterson'
        % Out of paranoia, make sure we use the right eye length parameters
        % for this method, so that the low angle linear approximation that
        % we tag on comes out right.
        switch (species)
            case 'Human'
                eyeLengthMm = EyeLength(species,'Rodieck');
            case 'Rhesus'
                eyeLengthMm = EyeLength(species,'PerryCowey');
            otherwise
                error('Unknown species specified');
        end
    
        % Set quadratic parameters
        switch (species)
            case 'Human'
                a = 0.035; b = 3.4; c1 = 0.1; 
            case 'Rhesus'
                a = 0.038; b = 4.21; c1 = 0.1;
            otherwise 
                error('Unknown species passed');
        end
        
        % Invert the quadratic
        c = c1-eccDegrees;
        eccMm = (-b + sqrt((b^2) - 4*a*c))/(2*a);
        
        % Don't return negative numbers
        eccMm(eccMm < 0) = 0;
        
        % Replace small angles by the linear approximation
        degreeThreshold = 0.2;
        index = find(eccDegrees < degreeThreshold);
        if (~isempty(index))
            factor = DegreesToRetinalMM(1,eyeLengthMm,'false');
            eccMM(index) = factor*eccDegrees(index);
        end

    case 'Linear'
        factor = DegreesToRetinalMM(1,eyeLengthMm,'false');
        eccMm = factor*eccDegrees;
        
    otherwise
        error('Unknown method passed')
end
end

