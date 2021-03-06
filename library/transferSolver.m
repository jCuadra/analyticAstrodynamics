classdef transferSolver
    % Solve transfer between two bodies given the two orbits
    
    properties
        % Defining parameters
        departureOrbit
        arrivalOrbit
        
        initialState
        leavingState
        arrivingState
        finalState
        
        % For the one computed or the found optimal
        transferOrbit
        
        % DeltaV s
        dVList
        dV
    end
    
    methods
        % Class constructor, provide initial and final orbits
        function obj = transferSolver(varargin)
            % Class constructor, calling conventions:
            % 1) departureOrbit, arrivalOrbit
            if(nargin ==2)
                obj.departureOrbit = varargin{1};
                obj.arrivalOrbit = varargin{2};
                
                if(obj.departureOrbit.gravP ~= obj.arrivalOrbit.gravP)
                    warning('central bodies seem to differ');
                end
            end
        end
        
        % Solve lambert problem given departure time and time of flight.
        % Initial/final orbit are provided in constructor
        function obj = solveFixedTransfer(obj, departure, tof)
            
            obj.initialState = obj.departureOrbit.computeState(departure);
            obj.finalState = obj.arrivalOrbit.computeState(departure+tof);
            
            lambert = lambertSolver(obj.departureOrbit);
            lambert = lambert.solveProblem(obj.initialState, obj.finalState);
            
            obj.transferOrbit = lambert.transfer;
            
            obj.leavingState = obj.transferOrbit.computeState(departure);
            obj.arrivingState = obj.transferOrbit.computeState(departure+tof);
            
            obj.dVList(1) = norm(obj.initialState.vVec-obj.leavingState.vVec);
            obj.dVList(2) = norm(obj.finalState.vVec-obj.arrivingState.vVec);
            
            obj.dV = sum(obj.dVList);
        end
        
        % Provide range of possible range for departures and time of
        % flight. The minimum delta v transfer is saved
        function obj = computePorkChop(obj, departureRange, tofRange, doPlot)
            % Compute pork chop
            [departure,tof] = meshgrid(departureRange,tofRange);
            len = numel(departure)
            deltaV = zeros(size(departure));
            parfor i=1:len
                auxObj = obj; % create a copy for parallelization
                auxObj = auxObj.solveFixedTransfer(departure(i), tof(i));
                deltaV(i) = auxObj.dV;
                if(mod(i,round(len/10))==0)
                    disp( [num2str(round(i/len*100)) '%'] );
                end
            end
            
            % save found optimal
            [deltaVMin,i] = min(deltaV(:));
            obj = obj.solveFixedTransfer(departure(i), tof(i));
            
            % plot
            if(doPlot)
                deltaV(deltaV>2*deltaVMin) = 2*deltaVMin;
                contourf(departure,tof,deltaV,'LineWidth',.1)
                colormap(flipud(colormap))
                xlabel('time of departure (days since J2000)')
                ylabel('time of flight(non-standard)')
                h = colorbar;
                ylabel(h, 'required \Deltav')
            end
        end
        
        function plot(obj)
            quiverScale = 3e6;
            obj.departureOrbit.plot()
            obj.arrivalOrbit.plot()
            obj.transferOrbit.plot()
            obj.initialState.plot(quiverScale)
            obj.leavingState.plot(quiverScale)
            obj.arrivingState.plot(quiverScale)
            obj.finalState.plot(quiverScale)
        end
    end
end

