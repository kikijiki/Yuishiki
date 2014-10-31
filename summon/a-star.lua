local AStar

return function(loader)
	if AStar then return AStar end

	AStar = {}

	local INF = 1/0

	local function lowest_f_score ( set, f_score )
		local lowest, bestNode
		for _, node in ipairs ( set ) do
			local score = f_score [ node ]
			if not lowest or score < lowest then
				lowest, bestNode = score, node
			end
		end
		return bestNode
	end

	local function not_in ( set, theNode )
		for _, node in ipairs ( set ) do
			if node == theNode then return false end
		end
		return true
	end

	local function remove_node ( set, theNode )
		for i, node in ipairs ( set ) do
			if node == theNode then
				set [ i ] = set [ #set ]
				set [ #set ] = nil
				break
			end
		end
	end

	local function unwind_path ( flat_path, map, current_node, out_func )
		if map [ current_node ] then
			table.insert ( flat_path, 1, out_func(map [ current_node ]) )
			return unwind_path ( flat_path, map, map [ current_node ], out_func )
		else
			return flat_path
		end
	end

	----------------------------------------------------------------
	-- pathfinding functions
	----------------------------------------------------------------

	function AStar.getPath ( start, goal, nodes, neighbor_func, heuristic_func, dist_func, out_func )
		local closedset = {}
		local openset = { start }
		local came_from = {}
		out_func = out_func or function(x) return x end

		local g_score, f_score = {}, {}
		g_score [ start ] = 0
		f_score [ start ] = g_score [ start ] + heuristic_func ( start, goal, nodes )

		while #openset > 0 do

			local current = lowest_f_score ( openset, f_score )
			if current == goal then
				local path = unwind_path ( {}, came_from, goal, out_func )
				table.insert ( path, out_func(goal) )
				return path
			end

			remove_node ( openset, current )
			table.insert ( closedset, current )
			local neighbors = neighbor_func ( current, nodes )
			for _, neighbor in ipairs ( neighbors ) do
				if not_in ( closedset, neighbor ) then
					local tentative_g_score = g_score [ current ] + dist_func ( current, neighbor, nodes )
					if not_in ( openset, neighbor ) or tentative_g_score < g_score [ neighbor ] then
						came_from 	[ neighbor ] = current
						g_score 	[ neighbor ] = tentative_g_score
						f_score 	[ neighbor ] = g_score [ neighbor ] + heuristic_func ( neighbor, goal, nodes )
						if not_in ( openset, neighbor ) then
							table.insert ( openset, neighbor )
						end
					end
				end
			end
		end
		return nil -- no valid path
	end

	return AStar
end
