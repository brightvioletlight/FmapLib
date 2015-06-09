classdef Test_Mesh_Features < matlab.unittest.TestCase
    % Unit test verifying the expected behavior and functionality of the
    % class 'Mesh_Features'.
    %
    % Usage Example:
    %                test1 = Test_Mesh_Features();
    %                test1.initialize_mesh_and_LB();
    %                test1.test_wks_and_hks();
    %
    % Note: As of 06/06, checks the euivalence between our implementation of
    % HKS and WKS and that of the original authors.
    
    
    properties
        shape_file  = '../../Data/kid_rodola/0001.isometry.1.off';
        ref_mesh    = [];
        LB          = [];
        eigs_num    = 100;
        area_type   = 'barycentric';
    end

    methods (TestClassSetup)
        % This code runs before any class instance is created.
        % See here: http://www.mathworks.com/help/matlab/matlab_prog/write-setup-and-teardown-code-using-classes.html
        function initialize_mesh_and_LB(obj)
            % Initializes the class instance to have a Mesh and an associated LB.
            obj.ref_mesh  = Mesh(obj.shape_file);
            obj.LB        = Laplace_Beltrami(obj.ref_mesh);            
            obj.LB.get_spectra(obj.eigs_num, obj.area_type);            
        end
    end
    
    methods (Test)
        function test_mean_curvature(obj)
            % For the moment only plotting our implementation of mean
            % curvature VS. Mesh Toolbox . Good for visual comparison.
            inmesh = obj.ref_mesh;            
            [Umin, Umax, Cmin, Cmax, Cmean, Cgauss, Normal] = compute_curvature(inmesh.vertices, inmesh.triangles);   
            subplot(1,2,1);
            options.face_vertex_color = perform_saturation(Cmean, 1.2);
            plot_mesh(inmesh.vertices, inmesh.triangles, options);
            shading interp; colormap jet(256); title('Mesh Toolbox MC.');
            subplot(1,2,2);
            our_mc = Mesh_Features.mean_curvature(inmesh, obj.LB);
            options.face_vertex_color = perform_saturation(our_mc, 1.2);
            plot_mesh(inmesh.vertices, inmesh.triangles, options);
            shading interp; colormap jet(256); title('Our MC.');
        end
        
        function test_wks_and_hks(obj)
            % Verifies that our versions of wks and hks are equal (and faster) than the
            % ones published by the original authors.
            nsamples = 100;            
            [evals, evecs]    = obj.LB.get_spectra(obj.eigs_num, obj.area_type);                        
            
            % wks check.
            [energies, sigma] = Mesh_Features.energy_sample_generator('log_linear', evals(2), evals(end), nsamples);
            wks_sig           = Mesh_Features.wave_kernel_signature(evecs(:,2:end), evals(2:end), energies, sigma);
            wks_aubrey_sig    = Test_Mesh_Features.wks_Aubry(evecs(:,2:end), evals(2:end), energies, sigma);
            obj.verifyTrue(all_close(wks_sig, wks_aubrey_sig));
            
            % hks check.
            energies          = Mesh_Features.energy_sample_generator('log_sampled', evals(2), evals(end), nsamples);
            hks_sig           = Mesh_Features.heat_kernel_signature(evecs(:,2:end), evals(2:end), energies);
            v_areas           = obj.ref_mesh.get_vertex_areas(obj.area_type);
            hks_sun           = Test_Mesh_Features.hks_Sun(evecs, evals, v_areas, energies, 1);
            obj.verifyTrue(all_close(hks_sig, hks_sun));            
            %TODO-P: check for graphs without area.
            % hks_sig           = Mesh_Features.heat_kernel_signature(evecs(:,2:end), evals(2:end), energies);
            % v_areas           = ones(inmesh.num_vertices, 1);
            % hks_sun           = Mesh_Features.hks_Sun(evecs, evals, v_areas, energies, 1);
            % all_close(hks_sig, hks_sun)
        end
        
        
        
    end

     
    
% %% TODO-E: Format! 
% Test vertex normal
% inmesh.set_vertex_normals();
% N = inmesh.vertex_normal;
% 
% figure;
% trisurf(inmesh.triangles, inmesh.vertices(:,1), inmesh.vertices(:,2), inmesh.vertices(:,3), 1);
% hold on;
% quiver3(inmesh.vertices(:,1), inmesh.vertices(:,2), inmesh.vertices(:,3), N(:,1), N(:,2), N(:,3));
% hold off;
% axis equal;
% 
% %% Mean curvature
% mean_curv = Mesh_Features.mean_curvature(inmesh, Laplace_Beltrami(inmesh), [0, 0.5, 2, 10]);
% 
% figure;
% subplot(2, 2, 1); trisurf(inmesh.triangles, inmesh.vertices(:,1), inmesh.vertices(:,2), inmesh.vertices(:,3), mean_curv(:,1));
% shading interp; axis equal; title('Mean Curvature');
% subplot(2, 2, 2); trisurf(inmesh.triangles, inmesh.vertices(:,1), inmesh.vertices(:,2), inmesh.vertices(:,3), mean_curv(:,2));
% shading interp; axis equal; title('Mean Curvature Smoothed');
% subplot(2, 2, 3); trisurf(inmesh.triangles, inmesh.vertices(:,1), inmesh.vertices(:,2), inmesh.vertices(:,3), mean_curv(:,3));
% shading interp; axis equal; title('Mean Curvature Smoothed');
% subplot(2, 2, 4); trisurf(inmesh.triangles, inmesh.vertices(:,1), inmesh.vertices(:,2), inmesh.vertices(:,3), mean_curv(:,4));
% shading interp; axis equal; title('Mean Curvature Smoothed');
% 
% %% Gauss curvature
% gauss_curv = Mesh_Features.gaussian_curvature(inmesh, [0, 20, 200, 500]);
% 
% figure;
% subplot(2, 2, 1); trisurf(inmesh.triangles, inmesh.vertices(:,1), inmesh.vertices(:,2), inmesh.vertices(:,3), gauss_curv(:,1));
% shading interp; axis equal; title('Gauss Curvature');
% subplot(2, 2, 2); trisurf(inmesh.triangles, inmesh.vertices(:,1), inmesh.vertices(:,2), inmesh.vertices(:,3), gauss_curv(:,2));
% shading interp; axis equal; title('Gauss Curvature Smoothed');
% subplot(2, 2, 3); trisurf(inmesh.triangles, inmesh.vertices(:,1), inmesh.vertices(:,2), inmesh.vertices(:,3), gauss_curv(:,3));
% shading interp; axis equal; title('Gauss Curvature Smoothed');
% subplot(2, 2, 4); trisurf(inmesh.triangles, inmesh.vertices(:,1), inmesh.vertices(:,2), inmesh.vertices(:,3), gauss_curv(:,4));
% shading interp; axis equal; title('Gauss Curvature Smoothed');
% 
% %% Gradient
% inmesh.set_vertex_normals();
% inmesh.set_triangle_areas();
% f = inmesh.vertices(:,1);
% df = Mesh.gradient_of_function(f, inmesh.vertices, inmesh.triangles, inmesh.triangle_normal, inmesh.triangle_areas);
% 
% bar = (inmesh.vertices(inmesh.triangles(:,1),:) + inmesh.vertices(inmesh.triangles(:,2),:) + inmesh.vertices(inmesh.triangles(:,3),:)) / 3;
% figure;
% trisurf(inmesh.triangles, inmesh.vertices(:,1), inmesh.vertices(:,2), inmesh.vertices(:,3), inmesh.vertices(:,1));
% hold on;
% quiver3(bar(:,1), bar(:,2), bar(:,3), df(:,1), df(:,2), df(:,3));
% hold off;
% shading interp; axis equal; 
% 
% Lf = Mesh.divergence_of_vector_field(df, inmesh.vertices, inmesh.triangles, inmesh.triangle_normal, inmesh.barycentric_v_area);
% LB = Laplace_Beltrami(inmesh);
% Lf2 = LB.W*f ./ inmesh.barycentric_v_area;
% assert(norm(Lf - Lf2)/norm(Lf) < 1e-8);
% 
% figure;
% trisurf(inmesh.triangles, inmesh.vertices(:,1), inmesh.vertices(:,2), inmesh.vertices(:,3), Lf);
% shading interp; axis equal; 
% 
%     
    

    methods (Static)
        
      function [WKS] = wks_Aubry(evecs, evals, energies, sigma)   
        % Implementation of the wks kernel by the original author: M.
        % Aubry.

        % Added by Panos to make the function work
        N            = length(energies);
        num_vertices = size(evecs, 1);
        log_E = log(abs(evals))';        
        e = energies;
        % End of Panos addition
                
        WKS = zeros(num_vertices, N);
        C = zeros(1,N); %weights used for the normalization of f_E

        for i = 1:N
            WKS(:, i) = sum(evecs.^2.* ...
                       repmat( exp((-(e(i) - log_E).^2) ./ (2*sigma.^2)), num_vertices, 1),2);
            
            C(i) = sum(exp((-(e(i)-log_E).^2)/(2*sigma.^2)));
        end

        % normalize WKS
        WKS(:,:) = WKS(:,:)./repmat(C,num_vertices,1);        
      end
      
      function [hks] = hks_Sun(evecs, evals, A, ts, scale)
        % Implementation of the hks kernel by the original authors: Sun et.
        % al
        
        % INPUTS
        %  evecs:  ith each column in this matrix is the ith eigenfunction of the Laplace-Beltrami operator
        %  evals:  ith element in this vector is the ith eigenvalue of the Laplace-Beltrami operator
        %  A:      ith element in this vector is the area associated with the ith vertex
        %  scale:  if scale = true, output the scaled hks
        %          o.w. ouput the hks that is not scaled
        %  ts :    time slices to evaluate the HKS

        % OUTPUTS
        %  hks: ith row in this matrix is the heat kernel signature of the ith vertex


           %area = sum(A);
           %A = (1/area) * A;
           %evals = area * evals;
           %evecs = sqrt(area) * evecs;

           if scale == true, 
              hks = abs( evecs(:, 2:end) ).^2 * exp( ( abs(evals(2)) - abs(evals(2:end)) )  * ts);
              Am = sparse([1:length(A)], [1:length(A)], A);
              colsum = sum(Am*hks);
              scale = 1.0./ colsum; 
              scalem = sparse([1:length(scale)], [1:length(scale)], scale);
              hks = hks * scalem;
           else
              hks = abs( evecs(:, 2:end) ).^2 * exp( - abs(evals(2:end)) * ts);

           end
      end
      
    end
    
end

