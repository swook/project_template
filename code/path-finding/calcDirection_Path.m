function e = calcDirection_Path (V, FV, A_pos, A_dest)
% CALCDIRECTION Calculates the direction an agent should move in this time step

	h = size(V, 1);     % Height of grid
	w = size(V, 2);     % Width of grid
	n = size(A_pos, 1); % Number of agents
	e = zeros(n, 2);    % New list of direction coordinates for agents

	% Calculate vector from agent to destination
	dR = A_dest - A_pos;

	% For each agent
	for p = 1:n
		% Get position coordinates of agent
		x = A_pos(p, 1);
		y = A_pos(p, 2);

		if FV(y, x) < 0.5
			continue;
		end

		if x + 1 > w
			% Upper X coordinate beyond width of grid
			dX = V(y, x) - V(y, x - 1);
			fX = FV(y, x) - FV(y, x - 1);
		elseif x - 1 < 1
			% Lower X coordinate before start of grid
			dX = V(y, x + 1) - V(y, x);
			fX = FV(y, x + 1) - FV(y, x);
		else
			% Normal case where not at grid edge
			dX = 0.5 * (V(y, x + 1) - V(y, x - 1));
			fX = 0.5 * (FV(y, x + 1) - FV(y, x - 1));
		end

		if y + 1 > h
			% Upper Y coordinate beyond height of grid
			dY = V(y, x) - V(y - 1, x);
			fY = FV(y, x) - FV(y - 1, x);
		elseif y - 1 < 1
			% Lower Y coordinate before start of grid
			dY = V(y + 1, x) - V(y, x);
			fY = FV(y + 1, x) - FV(y, x);
		else
			% Normal case where not at grid edge
			dY = 0.5 * (V(y + 1, x) - V(y - 1, x));
			fY = 0.5 * (FV(y + 1, x) - FV(y - 1, x));
		end

		dr      = dR(p, :);       % Vector from agent to destination
		glim    = 0.6 * norm(dr); % Limit gradient contribution to 80%
		                          % of dR contribution

		g       = [dX dY]; % Gradient vector
		g_norm  = norm(g); % 2-Norm of gradient
		if g_norm > glim
			g = g / g_norm * glim; % Limit gradient to glim
		end

		fg = [fX fY]; % Gradient vector for fire potential
		% disp(sprintf('dR: %.4g, g: %.4g, fg: %.4g\n', norm(dR(p, :)), g_norm, norm(fg)));

		numer = dR(p, :) + g - 100 * fg; % Add contribution from dest and grad-V
		norm_numer = norm(numer);

		if norm_numer == 0.0 % If numerator 0, don't divide by 0, set to 0
			e(p, :) = [0, 0];
		else
			e(p, :) = numer / norm(numer);
		end
	end
end