function [x_post] = calcResetMap(obj, model, x_pre, target)
    % Updates the system states using the reset map associated with the
    % discontinuous transition to the current domain to get the initial
    % states of the current domain.
    %   
    % 
    % Parameters: 
    %    model: the robot model of type RigitBodyModel
    %    qe_pre: pre-guard joint configuration @type colvec
    %    dqe_pre: pre-guard velocities @type colvec
    %    target: the target domain @type Domain
    %
    % Return values:
    %    x_post: post reset map states @type colvec
    
    qe_pre  = x_pre(model.qeIndices);
    dqe_pre = x_pre(model.dqeIndices); 
    
    if ~isempty(obj.ResetMap.ResetPoint)
        reset_pos = feval(obj.ResetMap.ResetPoint.Funcs.Kin, qe_pre);
        
        switch model.Type
            case 'planar'
                qe_pre(1:2) = qe_pre(1:2) - reset_pos;
            case 'spatial'
                qe_pre(1:3) = qe_pre(1:3) - reset_pos;
        end
        
    end
    
    
    
    % if swapping the stance/non-stance foot, multiply with
    % 'ResetMap.CoordinateRelabelMatrix'
    if ~isempty(obj.ResetMap.RelabelMatrix)
        qe_pre  = obj.ResetMap.RelabelMatrix * qe_pre;
        dqe_pre = obj.ResetMap.RelabelMatrix * dqe_pre;
    end
   
    
    
    % the joint configuration remains the same
    qe_post = qe_pre;
    % compute the impact map if the domain transition involves a rigid impact
    if obj.ResetMap.RigidImpact
        % jacobian of impact constraints
        Je = feval(target.HolonomicConstr.Funcs.Jac, qe_pre);
        
        % inertia matrix
        De = calcNaturalDynamics(model, qe_pre, dqe_pre);
        
        % Compute Dynamically Consistent Contact Null-Space from Lagrange
        % Multiplier Formulation
        DbarInv = Je * (De \ transpose(Je));
        I = eye(size(De));
        Jbar = De \ transpose(transpose(DbarInv) \ Je );
        Nbar = I - Jbar * Je;
        
        % Apply null-space projection
        dqe_post = Nbar * dqe_pre;
        %         nImpConstr = size(Je,1);
        %         A = [De -Je'; Je zeros(nImpConstr)];
        %         b = [De*dqe_pre; zeros(nImpConstr,1)];
        %         y = A\b;
        %
        %         ImpF = y((model.n_dofs+1):end);
        %         dqe_pre = y(model.qe_indices);
    else
        dqe_post = dqe_pre;
        
    end
    
    
    
    x_post = [qe_post; dqe_post];
 
end
