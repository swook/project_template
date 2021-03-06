% Copyright (c) 2013 Team Bambi
%
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

function stats = assemblyline(Gzero, Gmax, I, T, sigma, v, h, w, dests, nagent, N, F, timer, flags, extraparams)
% ASSEMBLYLINE Performs all calculations which are part of our model, namely:
%              1. Trail formation by agents on a grid of vegetation.
%              2. The spreading of a forest fire on the mentioned grid.
%              3. The path finding of an agent in the grid in the case of fire.

	% Initialise video file
	global Vis_WriteEnabled;
	Vis_WriteEnabled = false;

	if ~isfield(flags, 'NoVideo') || ~flags.NoVideo || ~isfield(flags, 'NoVis') || ~flags.NoVis
		cd 'visualisation'
		initVideo;
		cd ..
	end

	% Store statistics
	stats = struct('Escaped', 0, 'Dead', 0, 'SurvivalRate', 0);

	% Initialise other variables
	A_pos  = zeros(nagent, 2);
	A_dest = zeros(nagent, 2);

	% Perform trail formation
	if ~isfield(flags, 'NoTrail') || ~flags.NoTrail
		cd 'trail-formation'
		if ~isfield(flags, 'NoVis') || ~flags.NoVis
			extraparams.NoVis = false;
		else
			extraparams.NoVis = true;
		end
		[G, A_pos, A_dest] = trail(Gzero, Gmax, I, T, sigma, v, h, w, dests, nagent, N, extraparams);
		stats.G_postTrail = G;
		stats.A_pos_postTrail = A_pos;
		cd ..
	end

	% Return here if only trail formation is requested
	if isfield(flags, 'OnlyTrail') && flags.OnlyTrail
		return;
	end

	% Reset Bambi positions to provided A_pos if needed
	if isfield(extraparams, 'G')
		G = extraparams.G;
	end
	if isfield(extraparams, 'A_pos') && isfield(extraparams, 'A_dest')
		A_pos = extraparams.A_pos;
		A_dest = extraparams.A_dest;
	end

	% Fire Initialization
	if ~isfield(flags, 'NoFireInit') || ~flags.NoFireInit
		flag = 0;
		while(flag == 0)
			randPos = floor(size(G,1)*rand(1,2)) + 1;
			if (G(randPos(1), randPos(2)) < 0.25*Gmax)
				flag = 1;
				F(randPos(1), randPos(2)) = 1;
				timer(randPos(1), randPos(2)) = 5;
			end
		end
	end
	stats.F_initial = F;

	A_running = zeros(nagent, 1);

	% Loop for forest fire and path finding
	i = 0;
	while 1
		i = i + 1;
		tic;

		% Perform forest fire
		cd 'forest-fire'
		[F G timer] = Fire(F, G, timer, Gmax);
		[G] = generateNewG(F, G, Gmax);
		cd ..

		% Perform path finding
		cd 'path-finding'
		[G, A_pos, A_dest, A_running, e] = pathfind(G, F, Gmax, sigma, v, A_pos, A_dest, A_running, dests);
		cd ..

		% Remove the dead Bambis. We don't need them.
		[A_pos, A_dest, A_running, stats] = removeDeadBambis(F, A_pos, A_dest, A_running, h, w, flags, stats);

		% Visualise this situation
		if ~isfield(flags, 'NoVis') || ~flags.NoVis
			cd 'visualisation'
			visualise(Gmax, G, A_pos, e, F);
			cd ..
		end

		disp(['FIRE+PATH> Done with step ' num2str(i) ' after ' num2str(toc * 1000, 3) ' ms.' ]);

		% Check if we should stop. (Are all Bambis dead or at their destinations?)
		% Also stop if fire is extinguished.
		if size(A_pos, 1) < 1 || sum(double(F(:) > 0)) == 0
			break
		end
	end
	stats.Nsteps_Fire = i;

	% Close video file
	if ~isfield(flags, 'NoVideo') || ~flags.NoVideo || ~isfield(flags, 'NoVis') || ~flags.NoVis
		cd 'visualisation'
		closeVideo;
		cd ..
	end

	stats.SurvivalRate = (nagent - stats.Dead) / nagent * 100;
	disp(sprintf('\n> %d Bambis died while running away from the fire... RIP.\n', stats.Dead));
	disp(sprintf('\n> %d Bambis escaped successfully. Hooray!\n', stats.Escaped));
	disp(sprintf('\n> The survival rate of the Bambis is: %.1f\n', stats.SurvivalRate));
end
