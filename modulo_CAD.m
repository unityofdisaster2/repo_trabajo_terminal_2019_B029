%{
Implementacion inicial de modulo encargado de pasar valores del modelo
conceptual a COMSOL para su actualizacion en el diseno cad asociado
%}
function modulo_CAD(modelo, parametros)
    for ii = 1:size(parametros,1)
        try
            modelo.param.get(strcat('LL_',parametros{ii,1}));
            modelo.param.set(strcat('LL_',parametros{ii,1}),parametros{ii,2});
        catch ME
            msg = ['El parametro: <', parametros{ii,1},...
                '> no existe en el modelo de COMSOL'];
            causeException = MException('MATLAB:modulo_CAD:badParam',msg);
            ME = addCause(ME,causeException);
            
            fprintf('%s no existe en el modelo de COMSOL\n',parametros{ii,1});
            % rethrow(ME);
        end
        
    end
    % se considera que la primera geometria del modelo es la principal
    % y se muestra con mphgeom. Esta funcion ademas de mostrar en una
    % grafica de matlab la geometria, tambien la reconstruye con los
    % cambios que se hayan realizado anteriormente en los parametros.
    
    try
        mphgeom(modelo,'geom1','view','auto');
    catch ME
        
    end
    
    fprintf('ejecucion de SolidWorks exitosa\n'); 
end
